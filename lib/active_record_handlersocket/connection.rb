module ActiveRecordHandlerSocket
  module Connection
    def hs_reconnect!
      hs_read_connection.reconnect
      hs_write_connection.reconnect
      hs_reset_opened_indexes
      hs_active?
    end

    # XXX: stable_point cannot return correct status before open_index.
    #      connection establish with unknown port -> call stable_point -> retrun true
    def hs_active?
      [
        hs_read_connection.stable_point,
        hs_write_connection.stable_point
      ].all?
    end

    module PrivateMethods
      mattr_reader :hs_connections
      @@hs_connections = {}

      def hs_establish_connection(name = nil)
        case name
        when nil
          hs_establish_connection :read
          hs_establish_connection :write
        else
          config_key = "#{RAILS_ENV}_hs_#{name}"

          if config = ActiveRecord::Base.configurations[config_key]
            config = config.symbolize_keys

            connection = HandlerSocket.new :host => config[:host], :port => config[:port].to_s

            @@hs_connections.update name.to_sym => connection
          else
            raise ArgumentError, "unknown configuration: #{name}"
          end
        end
      end

      def hs_read_connection
        @@hs_connections[:read]
      end

      def hs_write_connection
        @@hs_connections[:write]
      end

      def hs_open_index(index_key, name = :read)
        setting = hs_fetch_key index_key

        if setting[:opened]
          return
        end

        config   = configurations["#{RAILS_ENV}_hs_#{name}"].symbolize_keys

        id       = setting[:id]
        database = config[:database]
        table    = table_name
        index    = setting[:index]
        fields   = setting[:fields].join ","

        connection = @@hs_connections[name]
        signal = connection.open_index id, database, table, index, fields

        case
        when signal == 0
          setting[:opened] = true
        when signal > 0
          error = connection.error
          raise ArgumentError, "invalid setting given: #{error}"
        else
          hs_reset_opened_indexes
          error = connection.error
          raise ActiveRecordHandlerSocket::CannotConnectError, "connection lost: #{error}"
        end
      end
    end
  end
end

module ActiveRecordHandlerSocket
  module Connection
    def hs_reconnect!
      hs_read_connection.reconnect
      hs_reset_opened_indexes
      hs_active?
    end

    # XXX: stable_point cannot return correct status before open_index.
    #      connection establish with unknown port -> call stable_point -> retrun true
    def hs_active?
      [
        hs_read_connection.stable_point
      ].all?
    end

    module PrivateMethods
      mattr_reader :hs_connections
      @@hs_connections = {}

      # TODO: writeread connection
      def hs_establish_connection(name = nil)
        case name
        when nil
          hs_establish_connection("#{RAILS_ENV}_hs_read")
        else
          if config = ActiveRecord::Base.configurations[name]
            config = config.symbolize_keys

            @@hs_connections.update(
              :read => HandlerSocket.new(:host => config[:host], :port => config[:port].to_s)
            )
          else
            raise ArgumentError, "unknown configuration: #{name}"
          end
        end
      end

      def hs_read_connection
        @@hs_connections[:read]
      end
    end
  end
end

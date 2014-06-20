module ActiveRecordHandlerSocket
  module Connection
    def hs_reconnect!
      hs_read_connection.reconnect
      hs_reset_opened_indexes
      hs_active?
    end

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
          config = ActiveRecord::Base.configurations[name].symbolize_keys

          @@hs_connections.update(
            :read => HandlerSocket.new(:host => config[:host], :port => config[:port].to_s)
          )
        end
      end

      def hs_read_connection
        @@hs_connections[:read]
      end
    end
  end
end

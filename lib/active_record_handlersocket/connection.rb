module ActiveRecordHandlerSocket
  module Connection
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

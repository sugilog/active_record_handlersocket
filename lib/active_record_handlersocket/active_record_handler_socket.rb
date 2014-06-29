module ActiveRecordHandlerSocket
  class CannotConnectError < StandardError; end
  class ConnectionLost     < StandardError; end
  class UnknownIndexError  < StandardError; end

  def self.included(c)
    [
      Manager,
      Finder,
      Writer,
    ].each do |_module|
      c.extend _module
      c.extend _module::PrivateMethods
      c.private_class_method *_module::PrivateMethods.instance_methods(false)
    end

    connection = Connection.new c.logger
    c.__send__ :cattr_reader, :hs_connection
    c.class_variable_set :@@hs_connection, connection
  end
end

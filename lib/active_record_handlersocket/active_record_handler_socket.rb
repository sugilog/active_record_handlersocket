module ActiveRecordHandlerSocket
  def self.included(c)
    [
      Manager,
      Finder,
      Connection
    ].each do |_module|
      c.extend _module
      c.extend _module::PrivateMethods
      c.private_class_method *_module::PrivateMethods.instance_methods(false)
    end

    c.__send__ :hs_establish_connection
  end
end
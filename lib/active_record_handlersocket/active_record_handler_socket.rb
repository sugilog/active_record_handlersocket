module ActiveRecordHandlerSocket
  class CannotConnectError < StandardError; end
  class ConnectionLost     < StandardError; end
  class UnknownIndexError  < StandardError; end

  def self.included(c)
    c.extend ClassMethods
    c.__send__ :include, InstanceMethods

    connection = Connection.establish_connection c.logger
    c.__send__ :cattr_accessor, :hs_connection
    c.hs_connection = connection
  end

  module ClassMethods
    def hs_reader(key, index, options = {})
      hs_connection.add_index_setting self, key, index, options
    end

    def hs_writer(options = {})
      options = options.merge :write => true
      hs_connection.add_index_setting self, ActiveRecordHandlerSocket::Connection::WRITER_KEY, "PRIMARY", options
    end

    def method_missing(method_name, *args, &block)
      case method_name.to_s
      when /^hsfind_(by|multi_by)_([_a-zA-Z]\w*)$/
        finder = :first if $1 == "by"
        finder = :multi if $1 == "multi_by"
        key    = $2
        hsfind(finder, key, args)
      else
        super
      end
    end

    def hsfind(finder, key, args)
      hs_connection.select self, finder, key, args
    end

    def hscreate(attributes)
      hs_connection.insert self, attributes
    end

    # no test
    def hsupdate(id, attributes)
      hs_connection.update self, id, attributes
    end

    # no test
    def hsdelete(id)
    end
  end

  # no test
  module InstanceMethods
    def hssave(validation = true)
      case
      when validation && !valid?
        false
      when new_record?
        hscreate
      else
        hsupdate
      end
    end

    def hscreate
      case
      when false == run_callback(:before_create)
        false
      when result = self.class.hscreate(self.attributes)
        self.id = result
        self.instance_variable_set :@new_record, false
        run_callback :after_create
        !!id
      else
        false
      end
    end

    def hsupdate
      case
      when false == run_callback(:before_update)
        callback_result
      when self.class.hsupdate(self.id, self.attributes)
        run_callback :after_update
        true
      else
        false
      end
    end

    def hsdestroy
      case
      when false == run_callback(:before_destroy)
        callback_result
      when self.class.hsdelete(self.id)
        run_callback :after_destroy
        true
      else
        false
      end
    end
  end
end

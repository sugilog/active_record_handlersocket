module ActiveRecordHandlerSocket
  class CannotConnectError < StandardError; end
  class ConnectionLost     < StandardError; end
  class UnknownIndexError  < StandardError; end

  def self.included(c)
    c.extend Interface

    connection = Connection.new c.logger
    c.__send__ :cattr_accessor, :hs_connection
    c.hs_connection = connection
  end

  module Interface
    def hs_writer(options = {})
      options = options.merge :write => true
      hs_connection.add_index_setting self, ActiveRecordHandlerSocket::Connection::WRITER_KEY, "PRIMARY", options
    end

    def hs_reader(key, index, options = {})
      hs_connection.add_index_setting self, key, index, options
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
      hs_connection.find self, finder, key, args
    end

    def hscreate(attributes)
      hs_connection.create self, attributes
    end
  end
end

module ActiveRecord
  class Base
    include ActiveRecordHandlerSocket

    def self.hs_writer(options = {})
      options = options.merge :write => true
      hs_connection.add_index_setting self, ActiveRecordHandlerSocket::Connection::WRITER_KEY, "PRIMARY", options
    end

    def self.hs_reader(key, index, options = {})
      hs_connection.add_index_setting self, key, index, options
    end
  end
end

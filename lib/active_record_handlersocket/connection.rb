module ActiveRecordHandlerSocket
  class Connection
    WRITER_KEY    = "__writer__"

    def self.establish_connection(logger, options = {})
      instance = new logger, options
      instance.establish_connection :read
      instance.establish_connection :write
      instance
    end

    attr_reader :logger, :model_class, :connections, :indexes, :index_count_cache

    def initialize(logger, options = {})
      @logger      = logger
      @model_class = options[:model_class] || ActiveRecord::Base
      @connections = {}
      @indexes     = {}
      @index_count_cache = 0
    end

    def establish_connection(name)
      config = connection_config name

      if config
        config = config.symbolize_keys
        connection = HandlerSocket.new :host => config[:host], :port => config[:port].to_s
        @connections.update name.to_sym => connection
      else
        raise ArgumentError, "unknown configuration: #{name}"
      end
    end

    def read_connection
      @connections[:read]
    end

    def write_connection
      @connections[:write]
    end

    def reconnect!
      read_connection.reconnect
      write_connection.reconnect
      reset_opened_indexes
      active?
    end

    # XXX: stable_point cannot return correct status before open_index.
    #      connection establish with unknown port -> call stable_point -> retrun true
    def active?
      [
        read_connection.stable_point,
        write_connection.stable_point
      ].all?
    end

    def open_index(model, index_key, name = :read)
      setting = fetch index_key

      if setting[:opened]
        return
      end

      config   = connection_config name

      id       = setting[:id]
      database = config[:database]
      table    = model.table_name
      index    = setting[:index]
      fields   = setting[:fields].join ","

      connection = name == :read ? read_connection : write_connection
      signal     = connection.open_index id, database, table, index, fields

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

    def connection_config(name)
      config_key = "#{RAILS_ENV}_hs_#{name}"
      @model_class.configurations[config_key].symbolize_keys
    end

    def index_count
      @index_count_cache += 1
    end

    def reset_opened_indexes
      @indexes.each do |_, setting|
        setting[:opened] = false
      end
    end

    def add_index_setting(model, index_key, index, options = {})
      columns = options[:columns] || model.column_names

      if @indexes.has_key?(index_key)
        warn "ActiveRecordHandlerSocket: #{index_key} was updated"
      end

      setting = {
        :id     => index_count,
        :index  => index,
        :fields => columns.map(&:to_s),
        :opened => false
      }

      @indexes.update index_key => setting
    end

    def index_key(model, key)
      "#{model.name}:#{key}"
    end

    def index_writer_key(model)
      index_key model, WRITER_KEY
    end

    def fetch(index_key)
      @indexes[index_key] or raise ActiveRecordHandlerSocket::UnknownIndexError, "unknown key given: #{index_key}"
    end
  end
end




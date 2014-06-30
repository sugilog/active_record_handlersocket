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
        current_config = {:host => config[:host], :port => config[:port].to_s}
        connection = HandlerSocket.new current_config
        connection.instance_variable_set :@_current_config, current_config
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
        reset_opened_indexes
        error = connection.error
        raise ActiveRecordHandlerSocket::CannotConnectError, "connection lost: #{error}"
      end
    end

    def connection_config(name)
      config_key = "#{RAILS_ENV}_hs_#{name}"
      @model_class.configurations[config_key].try(:symbolize_keys)
    end

    def index_count
      @index_count_cache += 1
    end

    def reset_opened_indexes
      @indexes.each do |_, setting|
        setting[:opened] = false
      end
    end

    def add_index_setting(model, key, index, options = {})
      index_key = index_key model, key
      columns   = options[:columns] || model.column_names
      columns   = columns.map &:to_s

      if options[:write]
        columns = columns - [model.primary_key]
      end

      if columns.empty?
        raise ArgumentError, "columns should assign without :#{model.primary_key}"
      end

      if @indexes.has_key?(index_key)
        warn "ActiveRecordHandlerSocket: #{index_key} was updated"
      end

      setting = {
        :id     => index_count,
        :index  => index,
        :fields => columns,
        :opened => false
      }

      @indexes.update index_key => setting

      index_key
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

    module Reader
      def select(model, finder, key, args)
        index_key = index_key model, key
        setting   = fetch index_key

        options  = args.extract_options!
        id       = setting[:id]
        operator = options[:operator] || "="

        open_index model, index_key

        case finder
        when :multi
          limit = options[:each_limit] || 1
          _args = args.map{|arg| [id, operator, Array(arg), limit] }

          results = read_connection.execute_multi _args

          results.map{|result|
            instantiate model, index_key, result
          }.flatten
        when :first
          result = read_connection.execute_single(id, operator, args)
          instance = instantiate model, index_key, result
          instance.first
        else
          raise ArgumentError, "unknown hsfind type: #{finder}"
        end
      end

      def instantiate(model, index_key, result_on_single)
        signal, result = result_on_single

        case
        when signal == 0
          setting = fetch index_key
          fields  = setting[:fields]

          result.map{|record|
            attrs = Hash[ *fields.zip(record).flatten ]
            model.__send__ :instantiate, attrs
          }
        when signal > 0
          raise ArgumentError, "invalid argument given: #{result}"
        else
          reset_opened_indexes
          raise ConnectionLost, result
        end
      end
    end

    module Writer
      def insert(model, attributes)
        index_key = index_writer_key model

        open_index model, index_key, :write

        setting = fetch index_key
        id      = setting[:id]

        values = to_a_write_values attributes, setting[:fields]
        result = write_connection.execute_insert id, values
        write_result result
      end

      # XXX: operator
      def update(model, record_id, attributes)
        index_key = index_writer_key model

        open_index model, index_key, :write

        setting  = fetch index_key
        id       = setting[:id]
        operator = "="
        limit    = 1
        offset   = 0

        values = to_a_write_values attributes, setting[:fields]
        result = write_connection.execute_update id, operator, Array(record_id), limit, offset, values
        write_result result
        record_id
      end

      def current_time_from_proper_timezone
        time = @model_class.default_timezone == :utc ? Time.now.utc : Time.now
        time.to_s(:db)
      end

      def to_a_write_values(attributes, fields)
        attributes = attributes.stringify_keys

        fields.inject [] do |map, field|
          case value = attributes[field]
          when nil
            if /^(?:updated|created)_(?:at|on)$/ =~ field
              value = current_time_from_proper_timezone
            end
          when TrueClass, FalseClass
            value = value ? 1 : 0
          when Time, Date
            value = value.to_s(:db)
          end

          map.push value
        end
      end

      def write_result(result_on_single)
        signal, result = result_on_single

        case
        when signal == 0
          # return PRIMARY KEY value
          result.first.first.to_i
        when signal > 0
          message = result == "121" ? "duplicate entry" : result
          raise ArgumentError, "invalid argument given: #{message}"
        else
          reset_opened_indexes
          raise ConnectionLost, result
        end
      end
    end

    include Reader
    include Writer
  end
end

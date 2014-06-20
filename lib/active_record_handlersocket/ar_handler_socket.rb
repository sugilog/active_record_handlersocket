module ActiveRecordHandlerSocket
  mattr_accessor :indexes
  @@indexes ||= {}

  mattr_reader :index_count_cache
  @@index_count_cache = 0

  class CannotConnecError < StandardError; end

  def self.included(c)
    c.extend ClassMethods
    c.extend PrivateClassMethods
    c.private_class_method *PrivateClassMethods.instance_methods(false)

    c.__send__ :hs_establish_connection
  end

  def self.index_count
    @@index_count_cache += 1
  end

  module ClassMethods
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
      options   = args.extract_options!
      index_key = hs_index_key(key)
      setting   = ActiveRecordHandlerSocket.indexes[index_key]
      id        = setting[:id]
      operator  = options[:operator] || "="

      hs_open_index(index_key)

      case finder
      # XXX: experimental
      when :multi
        _args = args.map{|arg|
          _arg = []
          _arg << setting[:id]
          _arg << operator
          _arg << [arg]
          _arg << options[:limit] if options[:limit]
          _arg
        }

        results = hs_read_connection.execute_multi(_args)

        results.map{|result|
          hs_instantiate(index_key, result)
        }.flatten
      when :first
        result = hs_read_connection.execute_single(setting[:id], operator, args)
        hs_instantiate(index_key, result).first
      else
        # XXX: Not Support
      end
    end
  end

  module PrivateClassMethods
    def handlersocket(key, index, fields)
      index_key = hs_index_key(key)

      if ActiveRecordHandlerSocket.indexes.has_key?(index_key)
        warn "#{self.name} handlersocket: #{key} was updated"
      end

      key = key

      ActiveRecordHandlerSocket.indexes.update(
        index_key => {
          :id     => ActiveRecordHandlerSocket.index_count,
          :index  => index,
          :fields => fields,
          :opened => false
        }
      )
    end

    def hs_open_index(index_key)
      setting = ActiveRecordHandlerSocket.indexes[index_key]

      if setting[:opened]
        return
      end

      config   = configurations["#{RAILS_ENV}_hs_read"].symbolize_keys

      id       = setting[:id]
      database = config[:database]
      table    = table_name
      index    = setting[:index]
      fields   = setting[:fields].join(",")

      signal = hs_read_connection.open_index(id, database, table, index, fields)

      case
      when signal == 0
        setting[:opened] = true
      when signal > 0
        error = hs_read_connection.error
        raise ArgumentError, "invalid setting given: #{error}"
      else
        error = hs_read_connection.error
        raise ActiveRecordHandlerSocket::CannotConnecError, "connection lost: #{error}"
      end
    end

    def hs_instantiate(index_key, result_on_single)
      signal, result = result_on_single

      case
      when signal == 0
        setting   = ActiveRecordHandlerSocket.indexes[index_key]
        fields    = setting[:fields]

        result.map do |record|
          attrs = Hash[ *fields.zip(record).flatten ]
          instantiate(attrs)
        end
      when signal > 0
        raise ArgumentError, "invalid argument given: #{result}"
      else
        raise ActiveRecordHandlerSocket::CannotConnecError, result
      end
    end

    def hs_index_key(key)
      [self.name, key].join(":")
    end

    # TODO: writeread connection
    def hs_establish_connection(name = nil)
      case name
      when nil
        hs_establish_connection("#{RAILS_ENV}_hs_read")
      else
        config = ActiveRecord::Base.configurations[name].symbolize_keys
        @@hs_connections ||= {}
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

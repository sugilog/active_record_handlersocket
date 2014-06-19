require 'handlersocket'

module ActiveRecord
  module ARHandlerSocket
    mattr_accessor :indexes
    @@indexes ||= {}

    mattr_reader :connection, :index_count_cache
    # XXX: readonly
    config       = ActiveRecord::Base.connection.instance_variable_get(:@config)
    @@connection = HandlerSocket.new(:host => config[:host], :port => config[:hs_port].to_s)

    @@index_count_cache = 0

    class CannotConnecError < StandardError; end

    def self.included(c)
      c.extend ClassMethods
      c.extend PrivateClassMethods
      c.private_class_method *PrivateClassMethods.instance_methods(false)
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
        setting   = ARHandlerSocket.indexes[index_key]
        id        = setting[:id]
        operator  = options[:operator] || "="

        open_index(index_key)

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

          results = ARHandlerSocket.connection.execute_multi(_args)

          results.map{|result|
            hs_instantiate(index_key, result)
          }.flatten
        when :first
          result = ARHandlerSocket.connection.execute_single(setting[:id], operator, args)
          hs_instantiate(index_key, result).first
        else
          # XXX: Not Support
        end
      end
    end

    module PrivateClassMethods
      def handlersocket(key, index, fields)
        index_key = hs_index_key(key)

        if ARHandlerSocket.indexes.has_key?(index_key)
          warn "#{self.name} handlersocket: #{key} was updated"
        end

        key = key

        ARHandlerSocket.indexes.update(
          index_key => {
            :id     => ARHandlerSocket.index_count,
            :index  => index,
            :fields => fields,
            :opened => false
          }
        )
      end

      def open_index(index_key)
        setting = ARHandlerSocket.indexes[index_key]

        if setting[:opened]
          return
        end

        config   = connection.instance_variable_get(:@config)

        id       = setting[:id]
        database = config[:database]
        table    = table_name
        index    = setting[:index]
        fields   = setting[:fields].join(",")

        signal = ARHandlerSocket.connection.open_index(id, database, table, index, fields)

        case
        when signal == 0
          setting[:opened] = true
        when signal > 0
          error = ARHandlerSocket.conneciton.error
          raise ArgumentError, "invalid setting given: #{error}"
        else
          # signal 2, Problem on assigned database name, table name, index name, or fields name
          raise ARHandlerSocket::CannotConnecError, "connection lost"
        end
      end

      def hs_instantiate(index_key, result_on_single)
        signal, result = result_on_single

        case
        when signal == 0
          setting   = ARHandlerSocket.indexes[index_key]
          fields    = setting[:fields]

          result.map do |record|
            attrs = Hash[ *fields.zip(record).flatten ]
            instantiate(attrs)
          end
        when signal > 0
          raise ArgumentError, "invalid argument given: #{result}"
        else
          raise ARHandlerSocket::CannotConnecError, result
        end
      end

      def hs_index_key(key)
        [self.name, key].join(":")
      end
    end
  end
end

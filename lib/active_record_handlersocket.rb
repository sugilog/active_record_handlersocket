require 'handlersocket'

module ActiveRecord
  module ARHandlerSocket
    mattr_accessor :handlersocket_indexes
    @@handlersocket_indexes ||= {}

    mattr_reader :connection
    # XXX: readonly
    config       = ActiveRecord::Base.connection.instance_variable_get(:@config)
    @@connection = HandlerSocket.new(:host => config[:host], :port => config[:hs_port].to_s)

    class CannotConnecError < StandardError; end

    def self.included(c)
      c.extend ClassMethods
      c.extend PrivateClassMethods
      c.private_class_method *PrivateClassMethods.instance_methods(false)
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
        options  = args.extract_options!
        setting  = ARHandlerSocket.handlersocket_indexes[key]
        id       = setting[:id]
        operator = options[:operator] || "="

        open_index(key)

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
            hs_instantiate(key, result)
          }.flatten
        when :first
          result = ARHandlerSocket.connection.execute_single(setting[:id], operator, args)
          hs_instantiate(key, result).first
        else
          # XXX: Not Support
        end
      end
    end

    module PrivateClassMethods
      def handlersocket(key, index, fields)
        if ARHandlerSocket.handlersocket_indexes.has_key?(key)
          warn "#{self.name} handlersocket: #{key} was updated"
        end

        key = key.to_s

        ARHandlerSocket.handlersocket_indexes.update(
          key => {
            :id     => key.object_id,
            :index  => index,
            :fields => fields,
            :opened => false
          }
        )
      end

      def open_index(key)
        setting = ARHandlerSocket.handlersocket_indexes[key]
        config  = connection.instance_variable_get(:@config)

        if setting[:opened]
          return
        end

        id       = setting[:id]
        database = config[:database]
        table    = table_name
        index    = setting[:index]
        fields   = setting[:fields].join(",")

        signal = ARHandlerSocket.connection.open_index(id, database, table, index, fields)

        case
        when signal.zero?
          setting[:opened] = true
        when signal > 0
          error = ARHandlerSocket.conneciton.error
          raise ArgumentError, "invalid setting given: #{error}"
        else
          # signal 2, Problem on assigned database name, table name, index name, or fields name
          raise ARHandlerSocket::CannotConnecError, "connection lost"
        end
      end

      def hs_instantiate(key, result_on_single)
        signal, result = result_on_single

        if signal >= 0
          setting = ARHandlerSocket.handlersocket_indexes[key]
          fields  = setting[:fields]

          result.each_with_object([]) do |record, map|
            attrs = Hash[ *fields.zip(record).flatten ]
            map.push( instantiate(attrs) )
          end
        else
          raise ARHandlerSocket::CannotConnecError, result
        end
      end
    end
  end
end

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
        if /^(find|find_all)_hs_with_(.+)$/ =~ method_name.to_s
          find_type = $1
          key       = $2.to_sym
          find_hs(find_type, key, args)
        else
          super
        end
      end

      def find_hs(find_type, key, args)
        options  = args.extract_options!
        setting  = ARHandlerSocket.handlersocket_indexes[key]
        id       = setting[:id]
        operator = options[:operator] || "="

        if find_type == "find_all"
          # XXX
          _args = args.map{|arg|
            _arg = []
            _arg << setting[:id]
            _arg << operator
            _arg << [arg]
            _arg << ( options[:limit] || _arg.last.size )
          }

          results = ARHandlerSocket.connection.execute_multi(_args)

          results.map{|result|
            hs_instantiate(key, result)
          }.flatten
        else
          result = ARHandlerSocket.connection.execute_single(setting[:id], operator, args)
          hs_instantiate(key, result).first
        end
      end
    end

    module PrivateClassMethods
      def handlersocket(key, index, fields)
        if ARHandlerSocket.handlersocket_indexes.has_key?(key)
          raise ArgumentError, "#{key} is already exists"
        else
          key = key.to_sym

          ARHandlerSocket.handlersocket_indexes.update(
            key => {
              :id     => key.object_id,
              :index  => index,
              :fields => fields
            }
          )

          open_index(key)
        end
      end

      def open_index(key)
        setting = ARHandlerSocket.handlersocket_indexes[key]
        config  = connection.instance_variable_get(:@config)

        id       = setting[:id]
        database = config[:database]
        table    = table_name
        index    = setting[:index]
        fields   = setting[:fields].join(",")

        signal = ARHandlerSocket.connection.open_index(id, database, table, index, fields)

        if signal >= 0
          true
        else
          raise ARHandlerSocket::CannotConnecError, "open index failed"
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

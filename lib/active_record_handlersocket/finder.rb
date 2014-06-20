module ActiveRecordHandlerSocket
  class CannotConnecError < StandardError; end

  module Finder
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
      setting   = hs_indexes[index_key]
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

    module PrivateMethods
      def hs_open_index(index_key)
        setting = hs_indexes[index_key]

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
          setting   = hs_indexes[index_key]
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
    end
  end
end

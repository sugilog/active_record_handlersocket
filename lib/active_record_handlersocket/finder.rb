module ActiveRecordHandlerSocket
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
      index_key = hs_index_key(key)
      setting   = hs_fetch_key(index_key)

      options  = args.extract_options!
      id       = setting[:id]
      operator = options[:operator] || "="

      hs_open_index(index_key)

      case finder
      when :multi
        limit = options[:each_limit] || 1
        _args = args.map{|arg| [id, operator, Array(arg), limit] }

        results = hs_read_connection.execute_multi(_args)

        results.map{|result|
          hs_instantiate(index_key, result)
        }.flatten
      when :first
        result = hs_read_connection.execute_single(id, operator, args)
        hs_instantiate(index_key, result).first
      else
        raise ArgumentError, "unknown hsfind type: #{finder}"
      end
    end

    module PrivateMethods
      def hs_instantiate(index_key, result_on_single)
        signal, result = result_on_single

        case
        when signal == 0
          setting = hs_fetch_key(index_key)
          fields  = setting[:fields]

          result.map{|record|
            attrs = Hash[ *fields.zip(record).flatten ]
            instantiate(attrs)
          }
        when signal > 0
          raise ArgumentError, "invalid argument given: #{result}"
        else
          hs_reset_opened_indexes
          raise ConnectionLost, result
        end
      end
    end
  end
end

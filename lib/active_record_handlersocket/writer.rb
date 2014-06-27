module ActiveRecordHandlerSocket
  module Writer
    def hscreate(attributes)
      index_key = hs_index_writer_key

      hs_open_index index_key, :write

      attributes = attributes.stringify_keys
      setting    = hs_fetch_key index_key
      id         = setting[:id]

      values = setting[:fields].inject [] do |map, field|
        case value = attributes[field]
        when nil
          if /^(?:updated|created)_(?:at|on)$/ =~ field
            value = hs_current_time_from_proper_timezone
          end
        when TrueClass, FalseClass
          value = value ? 1 : 0
        end

        map.push value
      end

      signal, result = hs_write_connection.execute_insert id, values
      result = result.first

      case
      when signal == 0
        # return PRIMARY KEY value
        result.first.to_i
      when signal > 0
        message =
          case result.to_i
          when 121
            "duplicate entry"
          else
            "unknown: #{result}"
          end

        raise ArgumentError, "invalid argument given: #{message}"
      else
        hs_reset_opened_indexes
        raise CannotConnectError, result
      end
    end

    module PrivateMethods
      def hs_current_time_from_proper_timezone
        time = default_timezone == :utc ? Time.now.utc : Time.now
        time.to_s
      end
    end
  end
end

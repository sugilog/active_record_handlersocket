module ActiveRecordHandlerSocket
  class UnknownIndexError < StandardError; end

  module Manager
    module PrivateMethods
      mattr_reader :hs_indexes, :hs_index_count_cache
      @@hs_indexes = {}
      @@hs_index_count_cache = 0

      def handlersocket(*args)
        options = args.extract_options!
        key     = args[0]
        index   = args[1]

        case
        when columns = args[2]
          ActiveSupport::Deprecation.warn "set columns as option, like; :columns => #{columns.inspect}"
        when columns = options[:columns]
          # ok
        else
          columns = column_names
        end

        index_key = hs_index_key(key)

        if @@hs_indexes.has_key?(index_key)
          warn "#{self.name} handlersocket: #{key} was updated"
        end

        @@hs_indexes.update(
          index_key => {
            :id     => hs_index_count,
            :index  => index,
            :fields => columns,
            :opened => false
          }
        )
      end

      def hs_index_key(key)
        [self.name, key].join(":")
      end

      def hs_fetch_key(index_key)
        @@hs_indexes[index_key] or raise UnknownIndexError, "unknown key given: #{index_key}"
      end

      def hs_index_count
        @@hs_index_count_cache += 1
      end

      def hs_reset_opened_indexes
        @@hs_indexes.each do |_, setting|
          setting[:opened] = false
        end
      end
    end
  end
end

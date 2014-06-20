module ActiveRecordHandlerSocket
  module Manager
    module PrivateMethods
      mattr_reader :hs_indexes, :hs_index_count_cache
      @@hs_indexes = {}
      @@hs_index_count_cache = 0

      def handlersocket(key, index, fields)
        index_key = hs_index_key(key)

        if @@hs_indexes.has_key?(index_key)
          warn "#{self.name} handlersocket: #{key} was updated"
        end

        @@hs_indexes.update(
          index_key => {
            :id     => hs_index_count,
            :index  => index,
            :fields => fields,
            :opened => false
          }
        )
      end

      def hs_index_key(key)
        [self.name, key].join(":")
      end

      def hs_index_count
        @@hs_index_count_cache += 1
      end
    end
  end
end

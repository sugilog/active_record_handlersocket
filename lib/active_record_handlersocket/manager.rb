module ActiveRecordHandlerSocket
  module Manager
    module PrivateMethods
      PRIMARY_INDEX = "PRIMARY"

      def hs_writer(options = {})
        options[:columns] ||= column_names
        options[:columns] = options[:columns] - [primary_key]

        if options[:columns].empty?
          raise ArgumentError, "columns should assign without :#{primary_key}"
        end

        index_key = hs_connection.index_writer_key self
        hs_connection.add_index_setting self, index_key, PRIMARY_INDEX, options
      end

      def hs_reader(key, index, options = {})
        index_key = hs_connection.index_key self, key
        hs_connection.add_index_setting self, index_key, index, options
      end
    end
  end
end

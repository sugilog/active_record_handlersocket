module ActiveRecordHandlerSocket
  class CannotConnectError < StandardError; end
  class ConnectionLost     < StandardError; end
  class UnknownIndexError  < StandardError; end

  def self.included(c)
    c.extend ClassMethods
    c.__send__ :include, InstanceMethods
    c.__send__ :include, PrivateInstanceMethods
    c.__send__ :private, *PrivateInstanceMethods.instance_methods(false)

    connection = Connection.establish_connection c.logger
    c.__send__ :cattr_accessor, :hs_connection
    c.hs_connection = connection
  end

  module ClassMethods
    def hs_reader(key, index, options = {})
      hs_connection.add_index_setting self, key, index, options
    end

    def hs_writer(options = {})
      options = options.merge :write => true
      hs_connection.add_index_setting self, ActiveRecordHandlerSocket::Connection::WRITER_KEY, "PRIMARY", options
    end

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
      hs_connection.select self, finder, key, args
    end

    def hscreate(attributes)
      hs_connection.insert self, attributes
    end

    # no test
    def hsupdate(id, attributes)
      hs_connection.update self, id, attributes
    end

    # no test
    def hsdelete(id)
    end
  end

  # no test
  module InstanceMethods
    def hssave(validation = true)
      case
      when validation && !valid?
        false
      when new_record?
        hscreate
      else
        hsupdate
      end
    end

    def hscreate
      if false == run_callback(:before_create)
        return false
      end

      hs_set_timestamps_on_create

      if result = self.class.hscreate(self.attributes)
        self.id = result
        self.instance_variable_set :@new_record, false
        run_callback :after_create
        !!id
      else
        false
      end
    end

    def hsupdate
      if false == run_callback(:before_update)
        return false
      end

      hs_set_timestamps_on_update

      if self.class.hsupdate(self.id, self.attributes)
        run_callback :after_update
        true
      else
        false
      end
    end

    def hsdestroy
      if false == run_callback(:before_destroy)
        return false
      end

      if self.class.hsdelete(self.id)
        run_callback :after_destroy
        true
      else
        false
      end
    end
  end

  # no test
  module PrivateInstanceMethods
    # ref: https://github.com/rails/rails/blob/master/activerecord/lib/active_record/timestamp.rb
    def hs_set_timestamps_on_create
      if self.record_timestamps
        current_time = current_time_from_proper_timezone

        all_timestamp_attributes.each do |column|
          if respond_to?(column) && respond_to?("#{column}=") && self.__send__(column).nil?
            write_attribute column.to_s, current_time
          end
        end
      end
    end

    # ref: https://github.com/rails/rails/blob/master/activerecord/lib/active_record/timestamp.rb
    def hs_set_timestamps_on_update
      if self.record_timestamps
        current_time = current_time_from_proper_timezone

        timestamp_attributes_for_update do |column|
          column = column.to_s
          next if attributes_changed? column
          write_attribute column, current_time
        end
      end
    end
  end
end

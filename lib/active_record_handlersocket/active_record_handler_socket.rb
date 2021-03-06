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
      hs_connection.delete self, id
    end
  end

  # no test
  module InstanceMethods
    def hssave(validation = true)
      if new_record?
        hscreate(validation)
      else
        hsupdate(validation)
      end
    end

    def hscreate(validation = true)
      if validation && !valid?
        return false
      end

      hs_run_callbacks :create do
        hs_set_timestamps_on_create
        if result = self.class.hscreate(self.attributes)
          self.id = result
          self.instance_variable_set :@new_record, false
          hs_changes_applied
          !!id
        else
          false
        end
      end
    end

    def hsupdate(validation = true)
      if validation && !valid?
        return false
      end

      hs_run_callbacks :update do
        hs_set_timestamps_on_update
        if result = self.class.hsupdate(self.id, self.attributes)
          hs_changes_applied
          !!result
        else
          false
        end
      end
    end

    def hsdestroy
      hs_run_callbacks :destroy do
        !!self.class.hsdelete(self.id)
      end
    end
  end

  # no test
  module PrivateInstanceMethods
    # ref: https://github.com/rails/rails/blob/master/activerecord/lib/active_record/timestamp.rb
    def hs_set_timestamps_on_create
      if self.record_timestamps
        current_time = current_time_from_proper_timezone

        hs_all_timestamp_attributes.each do |column|
          if respond_to?(column) && respond_to?("#{column}=") && self.__send__(column).nil?
            write_attribute column.to_s, current_time
          end
        end
      end
    end

    # ref: https://github.com/rails/rails/blob/master/activerecord/lib/active_record/timestamp.rb
    def hs_set_timestamps_on_update
      if hs_should_record_timestamps?
        current_time = current_time_from_proper_timezone

        hs_timestamp_attributes_for_update.each do |column|
          next unless respond_to?(column)
          column = column.to_s
          next if attribute_changed? column
          write_attribute column, current_time
        end
      end
    end

    def hs_changes_applied
      if respond_to?(:changes_applied, true)
        changes_applied
      else
        changed_attributes.clear
      end
    end

    # https://github.com/rails/rails/blob/v2.3.18/activerecord/lib/active_record/callbacks.rb#L343
    def hs_run_callbacks(kind, &block)
      if self.class.respond_to?("before_#{kind}_callback_chain") && self.class.respond_to?("after_#{kind}_callback_chain")
        if false == callback("before_#{kind}")
          return false
        end

        result = yield
        callback "after_#{kind}"
        result
      else
        run_callbacks kind, &block
      end
    end

    def hs_all_timestamp_attributes
      if respond_to?(:all_timestamp_attributes, true)
        all_timestamp_attributes
      else
        hs_timestamp_attributes_for_create + hs_timestamp_attributes_for_update
      end
    end

    def hs_timestamp_attributes_for_update
      [:updated_at, :updated_on]
    end

    def hs_timestamp_attributes_for_create
      [:created_at, :created_on]
    end

    def hs_should_record_timestamps?
      if respond_to?(:should_record_timestamps?, true)
        should_record_timestamps?
      else
        self.record_timestamps && changed?
      end
    end
  end
end

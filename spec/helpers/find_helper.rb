module FindHelper
  def add_index_setting(_connection)
    {
      model_class => [
        [ :id, "PRIMARY" ],
        [ :age_and_status, "index_people_on_age_and_status" ],
      ],
      another_model_class => [
        [ :id, "PRIMARY" ]
      ]
    }.each do |model, settings|
      settings.each do |setting|
        index_key = _connection.add_index_setting model, *setting
        _connection.open_index model, index_key
      end
    end

    {
      model_class => [
        [ "PRIMARY", :write => true ]
      ],
      another_model_class => [
        [ "PRIMARY", :write => true ]
      ]
    }.each do |model, settings|
      settings.each do |setting|
        index_key = _connection.add_index_setting model, ActiveRecordHandlerSocket::Connection::WRITER_KEY, *setting
        _connection.open_index model, index_key, :write
      end
    end
  end

  def find_all(klass, conditions)
    if active_record_version >= Gem::Version.new("4.0.0")
      # XXX: not relation object
      klass.where(conditions).to_a
    else
      klass.all(:conditions => conditions)
    end
  end

  def active_record_version
    if ActiveRecord.respond_to?(:version)
      ActiveRecord.version
    else
      Gem::Version.new(ActiveRecord::VERSION::STRING)
    end
  end
end

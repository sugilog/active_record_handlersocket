module FindHelper
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

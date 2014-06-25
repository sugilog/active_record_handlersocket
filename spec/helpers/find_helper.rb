module FindHelper
  def find_all(klass, conditions)
    if ActiveRecord.version >= Gem::Version.new("4.0.0")
      # XXX: not relation object
      klass.where(conditions).to_a
    else
      klass.all(:conditions => conditions)
    end
  end
end

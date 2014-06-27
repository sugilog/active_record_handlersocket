require 'active_record_handlersocket'

class Person < ActiveRecord::Base
  hs_reader :id, "PRIMARY"
  hs_reader :age_and_status, "index_people_on_age_and_status", :columns => %W[id name age status]
  hs_writer

  attr_reader :family_name, :born_year

  def self.active_record_version
    if ActiveRecord.respond_to?(:version)
      ActiveRecord.version
    else
      Gem::Version.new(ActiveRecord::VERSION::STRING)
    end
  end

  if active_record_version >= Gem::Version.new("3.0.0")
    after_find :set_born_year
    after_initialize :set_family_name

  else
    def after_find
      set_born_year
    end

    def after_initialize
      set_family_name
    end
  end

  private

  def set_born_year
    @born_year = Time.now.year - self.age if self.age
  end

  def set_family_name
    @family_name = self.name.split(" ").last if self.name
  end
end

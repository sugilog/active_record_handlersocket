require 'active_record_handlersocket'

class Person < ActiveRecord::Base
  handlersocket :id, "PRIMARY"
  handlersocket :age_and_status, "index_people_on_age_and_status", :columns => %W[id name age status]

  attr_reader :family_name, :born_year

  def after_find
    @born_year = Time.now.year - self.age
  end

  def after_initialize
    @family_name = self.name.split(" ").last
  end
end

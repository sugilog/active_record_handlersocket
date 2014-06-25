require 'active_record_handlersocket'

class Person < ActiveRecord::Base
  handlersocket :id, "PRIMARY"
  handlersocket :age_and_status, "index_people_on_age_and_status", :columns => %W[id name age status]

  attr_reader :family_name, :born_year

  after_find :set_born_year
  after_initialize :set_family_name

  private

  def set_born_year
    @born_year = Time.now.year - self.age
  end

  def set_family_name
    @family_name = self.name.split(" ").last
  end
end

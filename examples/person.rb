require 'active_record_handlersocket'

class Person < ActiveRecord::Base
  handlersocket :id, "PRIMARY"
  handlersocket :age_and_status, "index_people_on_age_and_status", :columns => %W[id name age status]
end

require 'active_record_handlersocket'

class Person < ActiveRecord::Base
  handlersocket :id, "PRIMARY", %W[id name age status]
  handlersocket :age_and_status, "index_people_on_age_and_status", %W[id name age status]
end

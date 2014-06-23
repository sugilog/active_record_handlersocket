require 'active_record_handlersocket'

class Hobby < ActiveRecord::Base
  handlersocket :id, "PRIMARY", %W[id person_id title]
end

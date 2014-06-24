require 'active_record_handlersocket'

class Hobby < ActiveRecord::Base
  handlersocket :id, "PRIMARY", :columns => %W[id person_id title]
end

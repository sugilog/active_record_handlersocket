require 'active_record_handlersocket'

class Hobby < ActiveRecord::Base
  hs_reader :id, "PRIMARY", :columns => %W[id person_id title]
  hs_writer
end

require 'active_record'
require File.join(File.dirname(File.expand_path(__FILE__)), 'configuration.rb')
require 'active_record_handlersocket'

class Hobby < ActiveRecord::Base
  handlersocket :id, "PRIMARY", %W[id person_id title]
end

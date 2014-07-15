require 'active_record_handlersocket'

class Hobby < ActiveRecord::Base
  hs_reader :id, "PRIMARY", :columns => %W[id person_id title]
  hs_writer

  attr_accessor :callback_called

  before_create :before_create_callback
  after_create  :after_create_callback
  before_update :before_update_callback
  after_update  :after_update_callback

  private

  def before_create_callback
    @callback_called ||= {}
    @callback_called[:before_create] = true
  end

  def after_create_callback
    @callback_called ||= {}
    @callback_called[:after_create] = true
  end

  def before_update_callback
    @callback_called ||= {}
    @callback_called[:before_update] = true
  end

  def after_update_callback
    @callback_called ||= {}
    @callback_called[:after_update] = true
  end
end

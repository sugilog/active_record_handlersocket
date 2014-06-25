require 'active_record'
require 'logger'
require 'fileutils'

ActiveRecord::Base.configurations = {
  "base" => {
    :adapter  => "mysql2",
    :host     => "localhost",
    :username => "rails",
    :database => "active_record_handler_socket",
    :encoding => "utf8"
  },
  "development_hs_read" => {
    :host     => "localhost",
    :port     => "9998",
    :database => "active_record_handler_socket"
  }
}

ActiveRecord::Base.establish_connection :base

log_dir = File.join(File.dirname(File.expand_path(__FILE__)), "..", "log" )
log_file = File.join(log_dir, "development.log")

FileUtils.mkdir_p(log_dir)
ActiveRecord::Base.logger = Logger.new(log_file)

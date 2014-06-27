require 'active_record'
require 'logger'
require 'fileutils'

ActiveRecord::Base.configurations = {
  "test" => {
    :adapter  => "mysql2",
    :host     => "localhost",
    :username => "rails",
    :database => "active_record_handler_socket_test",
    :encoding => "utf8"
  },
  "development_hs_read" => {
    :host     => "localhost",
    :port     => "9998",
    :database => "active_record_handler_socket_development" # unknown database
  },
  "development_hs_write" => {
    :host     => "localhost",
    :port     => "9999",
    :database => "active_record_handler_socket_development" # unknown database
  },
  "test_hs_read" => {
    :host     => "localhost",
    :port     => "9998",
    :database => "active_record_handler_socket_test"
  },
  "test_hs_write" => {
    :host     => "localhost",
    :port     => "9999",
    :database => "active_record_handler_socket_test"
  }
}

ActiveRecord::Base.establish_connection RAILS_ENV.to_sym

log_dir = File.join(File.dirname(File.expand_path(__FILE__)), "..", "log" )
log_file = File.join(log_dir, "test.log")

FileUtils.mkdir_p(log_dir)
ActiveRecord::Base.logger = Logger.new(log_file)

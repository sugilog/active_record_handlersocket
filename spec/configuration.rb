require 'active_record'

ActiveRecord::Base.configurations = {
  "base" => {
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
  "test_hs_read" => {
    :host     => "localhost",
    :port     => "9998",
    :database => "active_record_handler_socket_test"
  }
}

ActiveRecord::Base.establish_connection "base"

require 'logger'
require 'fileutils'

log_dir = File.join(File.dirname(File.expand_path(__FILE__)), "..", "log" )
log_file = File.join(log_dir, "test.log")

FileUtils.mkdir_p(log_dir)
ActiveRecord::Base.logger = Logger.new(log_file)

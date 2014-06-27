require 'active_record'
require 'logger'
require 'fileutils'

ActiveRecord::Base.configurations = {
  "development" => {
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
  },
  "development_hs_write" => {
    :host     => "localhost",
    :port     => "9998",
    :database => "active_record_handler_socket"
  },
  "benchmark" => {
    :adapter  => "mysql2",
    :host     => "localhost",
    :username => "rails",
    :database => "active_record_handler_socket_benchmark",
    :encoding => "utf8"
  },
  "benchmark_hs_read" => {
    :host     => "localhost",
    :port     => "9998",
    :database => "active_record_handler_socket_benchmark"
  },
  "benchmark_hs_write" => {
    :host     => "localhost",
    :port     => "9998",
    :database => "active_record_handler_socket_benchmark"
  }
}

ActiveRecord::Base.establish_connection RAILS_ENV.to_sym

log_dir = File.join(File.dirname(File.expand_path(__FILE__)), "..", "log" )
log_file = File.join(log_dir, "development.log")

FileUtils.mkdir_p(log_dir)
ActiveRecord::Base.logger = Logger.new(log_file)

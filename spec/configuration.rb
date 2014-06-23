require 'active_record'

RAILS_ENV = "development" unless defined? RAILS_ENV

ActiveRecord::Base.configurations = {
  "base" => {
    :adapter  => "mysql2",
    :host     => "localhost",
    :username => "rails",
    :database => "ar_handler_socket_test",
    :encoding => "utf8"
  },
  "development_hs_read" => {
    :host     => "localhost",
    :port     => "9998",
    :database => "ar_handler_socket_test"
  }
}

ActiveRecord::Base.establish_connection "base"

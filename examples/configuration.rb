require 'active_record'

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

ActiveRecord::Base.establish_connection "base"

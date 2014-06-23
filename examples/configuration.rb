RAILS_ENV = "development" unless defined? RAILS_ENV

ActiveRecord::Base.configurations = {
  "base" => {
    :adapter  => "mysql2",
    :host     => "localhost",
    :username => "rails",
    :database => "ar_handler_socket",
    :encoding => "utf8"
  },
  "development_hs_read" => {
    :host     => "localhost",
    :port     => "9998",
    :database => "ar_handler_socket"
  }
}

ActiveRecord::Base.establish_connection "base"

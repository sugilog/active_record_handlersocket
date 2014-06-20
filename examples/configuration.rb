ActiveRecord::Base.configurations = {
  "base" => {
    :adapter  => "mysql2",
    :host     => "localhost",
    :username => "rails",
    :database => "ar_handler_socket",
    :encoding => "utf8"
  },
  "hs_read" => {
    :host     => "localhost",
    :port     => "9998",
    :database => "ar_handler_socket"
  }
}

ActiveRecord::Base.establish_connection "base"

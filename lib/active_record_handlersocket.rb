require 'active_record'
require 'handlersocket'

%W[
  connection
  active_record_handler_socket
  base
].each do |file|
  require File.join("active_record_handlersocket", file)
end


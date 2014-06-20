require 'active_record'
require 'handlersocket'

%W[
  ar_handler_socket
  base
].each do |file|
  require File.join("active_record_handlersocket", file)
end


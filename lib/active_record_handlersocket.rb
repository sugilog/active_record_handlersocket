require 'active_record'
require 'handlersocket'

%W[
  ar_handler_socket.rb
].each do |file|
  require File.join("active_record_handlersocket", file)
end


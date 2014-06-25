require "bundler/gem_tasks"

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.pattern = "spec/**/*_spec.rb"
    spec.rspec_opts = ["-c"]
  end

  task :default => [:spec]
rescue LoadError
  warn "rspec/core/rake_task cannot load"
end

MYSQL_USER = "rails"

DATABASES = {
  :development => "active_record_handler_socket",
  :test        => "active_record_handler_socket_test",
  :benchmark   => "active_record_handler_socket_benchmark",
}

def mysql(query, options = {})
  _user = options[:user] || MYSQL_USER
  _db   = options[:database]

  puts ""

  begin
    sh %Q|mysql -u #{_user} #{_db} -e "#{query}"|
  rescue => e
    puts e.message
  end
end

import 'tasks/travis.rake'
import 'tasks/db.rake'
import 'tasks/benchmark.rake'


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

import 'tasks/travis.rake'
import 'tasks/db.rake'


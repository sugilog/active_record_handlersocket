# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "active_record_handlersocket/version"

Gem::Specification.new do |s|
  s.name        = "active_record_handlersocket"
  s.version     = ActiveRecordHandlersocket::VERSION
  s.authors     = ["Takayuki Sugita"]
  s.email       = ["sugilog@gmail.com"]
  s.homepage    = "https://github.com/sugilog/active_record_handlersocket"
  s.summary     = %q{HandlerSocket for ActiveRecord}
  s.description = %q{Easy-to-use handlersocket from existing ActiveRecord Models}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_runtime_dependency "handlersocket"

  if RUBY_VERSION >= "1.8.7"
    s.add_runtime_dependency "activerecord"
    s.add_development_dependency "rspec"
  else
    s.add_runtime_dependency "activerecord", "~> 2.3.18"
    s.add_development_dependency "rspec", "~> 2.11.0"
  end
end

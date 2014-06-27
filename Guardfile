#!:/usr/bin/env ruby

guard :rspec, :cmd => "bundle exec rspec" do
  watch %r{^spec/cases/.+_spec\.rb$}

  callback = lambda do
    "spec"
  end

  watch %r{^spec/(?:spec_helper|configuration).rb$}, &callback
  watch %r{^spec/(?:factories|helpers|mock)/.+\.rb$}, &callback
  watch %r{^lib/active_record_handlersocket.rb$}, &callback
  watch %r{^lib/active_record_handlersocket/.*\.rb$}, &callback
end

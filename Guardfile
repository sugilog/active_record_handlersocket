#!:/usr/bin/env ruby

guard :rspec, :cmd => "bundle exec rspec", :failed_mode => :none do
  watch %r{^spec/cases/.+_spec\.rb$} do |match|
    "#{match[0]}"
  end

  action = -> { "spec" }

  watch %r{^spec/(?:spec_helper|configuration).rb$} , &action
  watch %r{^spec/(?:factories|helpers|mock)/.+\.rb$}, &action
  watch %r{^lib/active_record_handlersocket.rb$}    , &action
  watch %r{^lib/active_record_handlersocket/.*\.rb$}, &action
end

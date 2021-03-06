begin
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
        Coveralls::SimpleCov::Formatter
  ]
  SimpleCov.start do
    add_filter "vendor"
    add_filter "spec"
  end
rescue LoadError
end

begin
  require 'rspec/its'
rescue LoadError => e
  warn e.inspect
end

RAILS_ENV = "test"

spec_dir = File.dirname(File.expand_path(__FILE__))

require File.join(spec_dir, "configuration")

require File.join(spec_dir, "mock", "person")
require File.join(spec_dir, "mock", "hobby")

require File.join(spec_dir, "helpers", "connection_helper")
require File.join(spec_dir, "helpers", "stub_helper")
require File.join(spec_dir, "helpers", "warning_helper")

require 'factory_girl'
require 'database_cleaner'

RSpec.configure do |config|
  config.mock_framework = :rspec
  config.color = true

  config.include ConnectionHelper
  config.include StubHelper
  config.include WarningHelper

  config.before :suite do
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.clean_with :truncation
  end

  config.before :all do
    FactoryGirl.reload
  end

  config.before :each do
    DatabaseCleaner.start
    fake_warning_log
  end

  config.after :each do
    reset_warning_log
    DatabaseCleaner.clean
  end
end

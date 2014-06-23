spec_dir = File.dirname(File.expand_path(__FILE__))

require File.join(spec_dir, "configuration")
require File.join(spec_dir, "mock", "person")
require File.join(spec_dir, "mock", "hobby")

RSpec.configure do |config|
  config.mock_framework = :rspec
end

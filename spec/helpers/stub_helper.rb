require 'rspec'

module StubHelper
  def stub_object(object, method, return_value)
    if rspec_version >= Gem::Version.new("3.0.0")
      expect(object).to receive(method).and_return(return_value)
    else
      object.stub(method).and_return(return_value)
    end
  end

  def rspec_version
    Gem::Version.new(RSpec::Version::STRING)
  end
end

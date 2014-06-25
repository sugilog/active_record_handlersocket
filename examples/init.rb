RAILS_ENV ||= "development"

%W[
  configuration
  person
  hobby
].each do |file|
  require File.join(File.dirname(File.expand_path(__FILE__)), file)
end

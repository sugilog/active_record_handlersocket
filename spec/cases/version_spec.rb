require 'spec_helper'

describe "VersionSpec" do
  it "should declared version" do
    expect(ActiveRecordHandlersocket::VERSION).not_to be_nil
  end
end

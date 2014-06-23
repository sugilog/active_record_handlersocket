require 'spec_helper'

describe "FinderSpec" do
  let :klass do
    Person
  end

  describe "finder" do
    context "when defined by handlersocket" do
      before :each do
        klass.delete_all
      end

      it "should call hsfind with method_missing" do
        expect(klass).not_to respond_to :hsfind_by_id
        expect(klass.hsfind_by_id(1)).to be_nil
      end
    end

    context "when before definition by handlersocket" do
      it "should raise error" do
        expect{
          klass.hsfind_by_name("Bob")
        }.to raise_error(ActiveRecordHandlerSocket::UnknownIndexError)
      end

      it "should include unknown key in error message" do
        message = ""

        begin
          klass.hsfind_by_name("Bob")
        rescue ActiveRecordHandlerSocket::UnknownIndexError => e
          message = e.message
        end

        expect(message).to include "#{klass.name}:name"
      end
    end
  end
end

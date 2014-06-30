require 'spec_helper'

describe ActiveRecord::Base do
  let :klass do
    Person
  end

  let :another_klass do
    Hobby
  end

  let :connection do
    ActiveRecord::Base.hs_connection
  end

  before :each do
    @bob      = FactoryGirl.create(:bob)
    @pharrell = FactoryGirl.create(:pharrell)
    @john     = FactoryGirl.create(:john)
  end

  describe ".hs_reader" do
    context "when same key from another model" do
      describe "Person:id" do
        subject {
          index_key = connection.index_key klass, :id
          setting   = connection.fetch index_key
          setting[:fields]
        }

        it { should eql %W[id name age status] }
      end

      describe "Hobby:id" do
        subject {
          index_key = connection.index_key another_klass, :id
          setting = connection.fetch index_key
          setting[:fields]
        }

        it "should have Hobby columns" do
          should eql %W[id person_id title]
        end
      end
    end

    context "when columns options" do
      before :each do
        klass.hs_reader :test, "PRIMARY", :columns => %W[id name]
      end

      subject {
        index_key = connection.index_key klass, :test
        setting = connection.fetch index_key
        setting[:fields]
      }

      it "should have given columns" do
        should eql %W[id name]
      end
    end
  end

  describe ".hs_writer" do
    context "when same key from another model" do
      describe "Person:__writer__" do
        subject {
          index_key = connection.index_writer_key klass
          setting = connection.fetch index_key
          setting[:fields]
        }

        it "should have Person columns" do
          should eql %W[name age status]
        end
      end

      describe "Hobby:__writer__" do
        subject {
          index_key = connection.index_writer_key another_klass
          setting = connection.fetch index_key
          setting[:fields]
        }

        it "should have Hobby columns" do
          should eql %W[person_id title created_at updated_at]
        end
      end
    end

    context "when columns options" do
      before :each do
        klass.hs_writer :columns => %W[id name]
      end

      subject {
        index_key = connection.index_writer_key klass
        setting = connection.fetch index_key
        setting[:fields]
      }

      it "should have given columns without primary key" do
        should eql %W[name]
      end
    end

    describe "index fixed" do
      subject {
        index_key = connection.index_writer_key klass
        setting = connection.fetch index_key
        setting[:index]
      }

      it {
        should eql "PRIMARY"
      }
    end
  end

  describe ".method_missing" do
    context "default behavior" do
      describe "find_by_id" do
        subject { klass.find_by_id 1 }

        it do
          should eql @bob
        end
      end

      describe "find_by_age_and_status" do
        subject { klass.find_by_age_and_status 36, true }

        it do
          should eql @john
        end
      end
    end

    context "call .hsfind_by_xxx" do
      describe "for id" do
        subject { klass.hsfind_by_id 1 }

        it do
          should eql @bob
        end
      end

      # XXX: hsfind with true/false
      describe "for age_and_status" do
        subject { klass.hsfind_by_age_and_status 36, 1 }

        it do
          should eql @john
        end
      end
    end

    context "call .hsfind_multi_by_xxx" do
      describe "for id" do
        subject { klass.hsfind_multi_by_id 1, 3 }

        it do
          should eql [@bob, @john]
        end
      end

      # XXX: hsfind with true/false
      describe "for age_and_status" do
        subject { klass.hsfind_multi_by_age_and_status [36, 1] }

        it do
          should eql [@john]
        end
      end
    end
  end


    # context "when defined by handlersocket" do
    #   before :each do
    #     model_class.delete_all
    #   end

    #   context "for :first" do
    #     it "should call find with method_missing" do
    #       expect(model_class).not_to respond_to(:hsfind_by_id)
    #       expect(connection.find(model_class, :first, :id, [1])).to be_nil
    #     end
    #   end

    #   context "for :multi" do
    #     it "should call find with method_missing" do
    #       expect(model_class).not_to respond_to(:hsfind_multi_by_id)
    #       expect(model_class.hsfind_multi_by_id(1)).to be_empty
    #     end
    #   end
    # end

    # context "when before definition by handlersocket" do
    #   context "for :first" do
    #     it "should raise error" do
    #       expect{
    #         model_class.hsfind_by_name("Bob")
    #       }.to raise_error(ActiveRecordHandlerSocket::UnknownIndexError)
    #     end
    #   end

    #   context "for :multi" do
    #     it "should raise error" do
    #       expect{
    #         model_class.hsfind_multi_by_name("Bob")
    #       }.to raise_error(ActiveRecordHandlerSocket::UnknownIndexError)
    #     end
    #   end
    # end
end

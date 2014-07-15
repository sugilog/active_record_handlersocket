require 'spec_helper'

describe ActiveRecordHandlerSocket::Connection do
  let :klass do
    ActiveRecordHandlerSocket::Connection
  end

  let :model_class do
    Person
  end

  let :another_model_class do
    Hobby
  end

  let! :connection do
    klass.establish_connection ActiveRecord::Base.logger
  end

  before :each do
    @bob      = FactoryGirl.create(:bob)
    @pharrell = FactoryGirl.create(:pharrell)
    @john     = FactoryGirl.create(:john)

    add_index_setting connection
  end

  describe "#select" do
    context "when records exist" do
      context "for :first" do
        describe "should get one record by id" do
          let(:person) { model_class.find_by_id 1 }
          subject      { connection.select model_class, :first, :id, [1] }
          it           { should_not be_nil }
          it           { should eql person }
        end

        describe "should get nil by unknown id" do
          let(:person) { model_class.find_by_id 9 }
          subject      { connection.select model_class, :first, :id, [9] }
          it           { should be_nil }
          it           { should eql person }
        end
      end

      context "for :multi" do
        describe "should get one record by id" do
          let(:person) { find_all model_class, :id => 1 }
          subject      { connection.select model_class, :multi, :id, [1] }
          its(:size)   { should eql 1 }
          it           { should eql person }
        end

        describe "should get some records by ids" do
          let(:people) { find_all model_class, :id => [1, 2] }
          subject      { connection.select model_class, :multi, :id, [1, 2] }
          it           { should eql people }
        end

        describe "should get empty array by unknown id" do
          let(:people) { find_all model_class, :id => 9 }
          subject      { connection.select model_class, :multi, :id, [9] }
          it           { should be_empty }
          it           { should eql people }
        end
      end
    end

    describe "select with options" do
      context "for :single" do
        context "with '>' operator option" do
          describe "record exists" do
            subject { connection.select model_class, :first, :id, [0, {:operator => ">"}] }
            it      { should be_kind_of model_class }
          end

          describe "record not found" do
            subject { connection.select model_class, :first, :id, [3, {:operator => ">"}] }
            it      { should be_nil }
          end
        end

        context "with '<' operator option" do
          describe "record exists" do
            let(:person) { model_class.find_by_id 2 }
            subject      { connection.select model_class, :first, :id, [3, {:operator => "<"}] }
            it           { should be_kind_of model_class }
            it           { should eql person }
          end

          describe "record not found" do
            subject { connection.select model_class, :first, :id, [0, {:operator => "<"}] }
            it      { should be_nil }
          end
        end

        context "with each_limit option" do
          let(:person) { model_class.find_by_id 2 }
          subject      { connection.select model_class, :first, :id, [3, {:operator => "<", :each_limit => 10}] }
          it { should_not be_nil }
          it { should eql person }
          it { should_not be_kind_of Array }
        end
      end

      context "for :multi" do
        context "with '>' operator option" do
          describe "records exists" do
            subject     { connection.select model_class, :multi, :id, [0, {:operator => ">"}] }
            its(:size)  { should eql 1 }
            its(:first) { should be_kind_of model_class }
          end

          describe "records not found" do
            subject { connection.select model_class, :multi, :id, [3, {:operator => ">"}] }
            it      { should be_empty }
          end
        end

        context "with '<' operator option" do
          describe "records exists" do
            let(:people) { find_all model_class, :id => 2 }
            subject      { connection.select model_class, :multi, :id, [3, {:operator => "<"}] }
            it           { should eql people }
          end

          describe "records not found" do
            subject { connection.select model_class, :multi, :id, [0, {:operator => "<"}] }
            it      { should be_empty }
          end
        end

        context "with each_limit option" do
          let(:people) { find_all model_class, :id => [1, 2, 3] }
          subject      { connection.select model_class, :multi, :id, [0, {:operator => ">", :each_limit => 10}] }
          it           { should eql people }
        end

        context "with discarded limit option" do
          subject { connection.select model_class, :multi, :id, [0, {:operator => ">", :limit => 10}] }
          it      { should eql [@bob] }
        end
      end
    end

    describe "with multi column index" do
      context "for :single" do
        context "when use 1st sequence column" do
          let(:person) { model_class.find_by_age 36 }
          subject      { connection.select model_class, :first, :age_and_status, [36] }
          it           { should eql person }
        end

        context "when use all sequence columns" do
          let(:person) { model_class.find_by_age_and_status 36, false }
          # XXX: Cannot use `true/false`
          subject      { connection.select model_class, :first, :age_and_status, [36, 0] }
          it           { should eql person }
        end

        context "when use not 1st sequence column" do
          # XXX: Cannot use `true/false`
          subject { connection.select model_class, :first, :age_and_status, [0] }
          it      { should be_nil }
        end
      end

      context "for :multi" do
        context "when use 1st sequence column" do
          let(:people) { find_all model_class, :age => 36 }

          describe "should select records" do
            subject      { connection.select model_class, :multi, :age_and_status, [36, {:each_limit => 10}] }
            its(:size)   { should eql 2 }
            it           { should eql people }
          end

          describe "should select records by array assign" do
            subject    { connection.select model_class, :multi, :age_and_status, [[36], {:each_limit => 10}] }
            its(:size) { should eql 2 }
            it         { should eql people }
          end
        end

        context "when use all sequence columns" do
          describe "should select records" do
            let(:people) { find_all model_class, :age => 36, :status => false }
            # XXX: Cannot use `true/false`
            subject      { connection.select model_class, :multi, :age_and_status, [[36, 0], {:each_limit => 10}] }
            its(:size)   { should eql 1 }
            it           { should eql people }
          end

          describe "should select records by multi condition" do
            let(:people) { [find_all(model_class, :age => 36, :status => false), find_all(model_class, :age => 36, :status => true)].flatten }
            # XXX: Cannot use `true/false`
            subject      { connection.select model_class, :multi, :age_and_status, [[36, 0], [36, 1], {:each_limit => 10}] }
            its(:size)   { should eql 2 }
            it           { should eql people }
          end
        end

        context "when use not 1st sequence column" do
          subject { connection.select model_class, :multi, :age_and_status, [[0], {:each_limit => 10}] }
          it      { should be_empty }
        end
      end
    end

    describe "with active_record callbacks" do
      context "for :single" do
        describe "should work after_find callback" do
          before :each do
            @record = connection.select model_class, :first, :id, [1]
          end

          subject         { @record }
          its(:born_year) { should eql Time.now.year - @record.age }
        end

        describe "should work after_initialize callback" do
          before :each do
            @record = connection.select model_class, :first, :id, [1]
          end
          subject           { @record }
          its(:family_name) { should eql @record.name.split(" ").last }
        end
      end

      context "for :multi" do
        describe "should work after_find callback" do
          before :each do
            @record = connection.select model_class, :multi, :id, [1, 2]
          end

          its(:size)             { should eql 2 }
          its("first.born_year") { should eql Time.now.year - @record.first.age }
          its("last.born_year")  { should eql Time.now.year - @record.last.age }
        end

        describe "should work after_initialize callback" do
          before :each do
            @record = connection.select model_class, :multi, :id, [1, 2]
          end

          its(:size)               { should eql 2 }
          its("first.family_name") { should eql @record.first.name.split(" ").last }
          its("last.family_name")  { should eql @record.last.name.split(" ").last }
        end
      end
    end

    describe "with connection" do
      before :each do
        connection.reconnect!
      end

      subject { connection.indexes[connection.index_key(model_class, :id)][:opened] }
      it      { should be false }

      describe "select after reconnect" do
        subject { lambda { connection.select model_class, :first, :id, [1] } }
        it      { should_not raise_error }
      end

      describe "indexes after select" do
        before :each do
          connection.select model_class, :first, :id, [1]
        end

        subject { connection.indexes[connection.index_key(model_class, :id)][:opened] }
        it      { should be true }
      end
    end
  end

  describe "instantiate" do
    context "when valid result" do
      describe "should return single record" do
        subject { connection.instantiate model_class, connection.index_key(model_class, :id), [0, [["1", "MySQL", "19", "1"]]] }
        its(:size) { should eql 1 }
      end

      describe "should return type casted values" do
        subject      { connection.instantiate(model_class, connection.index_key(model_class, :id), [0, [["1", "MySQL", "19", "1"]]]).first }
        its(:id)     { should eql 1 }
        its(:name)   { should eql "MySQL" }
        its(:age)    { should eql 19 }
        its(:status) { should be true }
      end

      describe "should return multi record" do
        subject    { connection.instantiate model_class, connection.index_key(model_class, :id), [0, [["1", "MySQL", "19", "1"], ["2", "%#123", "55", "0"]]] }
        its(:size) { should eql 2 }
      end

      describe "should return type casted values in each object" do
        subject             { connection.instantiate model_class, connection.index_key(model_class, :id), [0, [["1", "MySQL", "19", "1"], ["2", "%#123", "55", "0"]]] }
        its("first.id")     { should eql 1 }
        its("first.name")   { should eql "MySQL" }
        its("first.age")    { should eql 19 }
        its("first.status") { should be true }
        its("last.id")      { should eql 2 }
        its("last.name")    { should eql "%#123" }
        its("last.age")     { should eql 55 }
        its("last.status")  { should be false }
      end
    end

    context "when invalid result" do
      subject { lambda { connection.instantiate model_class, connection.index_key(model_class, :id), [2, "kpnum"] } }
      it      { should raise_error ArgumentError }
    end

    context "when connection error" do
      before :each do
        connection.select(model_class, :first, :id, [1])
        connection.select(another_model_class, :first, :id, [1])
      end

      it "should raise error and mark opened_index closed" do
        expect(connection.indexes[connection.index_key(model_class, :id)][:opened]).to be
        expect(connection.indexes[connection.index_key(another_model_class, :id)][:opened]).to be

        expect{
          connection.instantiate model_class, connection.index_key(model_class, :id), [-1, "connection lost"]
        }.to raise_error(ActiveRecordHandlerSocket::ConnectionLost)

        expect(connection.indexes[connection.index_key(model_class, :id)][:opened]).not_to be
        expect(connection.indexes[connection.index_key(another_model_class, :id)][:opened]).not_to be
      end
    end
  end
end

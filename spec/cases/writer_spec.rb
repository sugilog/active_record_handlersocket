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

  describe "#insert" do
    context "with given attributes" do
      subject {
        id = connection.insert model_class, :name => "Test", :age => 24, :status => true
        model_class.find_by_id id
      }

      its(:id)     { should be > 3 }
      its(:name)   { should == "Test" }
      its(:age)    { should == 24 }
      its(:status) { should == true }
    end

    # After handlersocket version up (over 0.0.2) nil will be supported.
    context "with nil value given" do
      it "should callable but having nil" do
        expect{
          connection.insert model_class, :name => "Test", :age => 24, :status => nil
        }.to raise_error TypeError
      end
    end

    context "with unique index" do
      describe "save first time" do
        subject {
          id = connection.insert another_model_class, :person_id => 1, :title => "Hobby"
          another_model_class.find_by_id id
        }

        its(:person_id) { should == 1 }
        its(:title)     { should == "Hobby" }
      end

      it "should raise error" do
        connection.insert another_model_class, :person_id => 1, :title => "Hobby"

        expect{
          connection.insert another_model_class, :person_id => 1, :title => "Hobby"
        }.to raise_error(ArgumentError)
      end
    end

    context "with timestamp" do
      it "should fill updated_at" do
        id = connection.insert another_model_class, :person_id => 1, :title => "Hobby"

        record = another_model_class.find_by_id id

        expect(record.updated_at).to be_within(2).of(Time.now)
      end

      it "should fill created_at" do
        id = connection.insert another_model_class, :person_id => 1, :title => "Hobby"

        record = another_model_class.find_by_id id

        expect(record.updated_at).to be_within(2).of(Time.now)
      end
    end

  end

  describe "#insert many" do
    let! :auto_increment do
      model_class.connection.__send__(:select, <<-SQL).to_a.first["AUTO_INCREMENT"]
SELECT AUTO_INCREMENT
FROM   INFORMATION_SCHEMA.TABLES
WHERE  TABLE_SCHEMA = '#{model_class.configurations[RAILS_ENV][:database]}'
AND    TABLE_NAME = '#{model_class.table_name}'
      SQL
    end

    before :each do
      10000.times do |i|
        @id = connection.insert model_class, :name => "Name#{i}", :age => i, :status => rand(2).zero?
      end
    end

    subject { @id }

    it { should == model_class.last.id }
    it { should == auto_increment - 1 + 10000 }
  end

  describe "#update" do
    context "with given attributes" do
      subject {
        id = connection.update model_class, 1, :name => "Test", :age => 24, :status => true
        model_class.find_by_id id
      }

      its(:id)     { should == 1 }
      its(:name)   { should == "Test" }
      its(:age)    { should == 24 }
      its(:status) { should == true }
    end

    # After handlersocket version up (over 0.0.2) nil will be supported.
    context "with nil value given" do
      it {
        expect{
          connection.update model_class, 1, :name => "Test", :age => 24, :status => nil
        }.to raise_error TypeError
      }
    end

    context "with unique index" do
      before :each do
        @dance         = FactoryGirl.create(:dance)
        @another_dance = FactoryGirl.build(:dance)
        @another_dance.id = nil
        @another_dance.title = "Another Dance"
        @another_dance.save
      end

      it {
        expect{
          connection.update another_model_class, @another_dance.id, :person_id => 1, :title => "Dance"
        }.to raise_error ArgumentError
      }
    end

    context "with timestamp" do
      before :each do
        @dance = FactoryGirl.build(:dance)
        @dance.updated_at = Date.yesterday.to_time
        @dance.created_at = Date.yesterday.to_time
        @dance.save

        expect(@dance.updated_at).not_to be_nil
        expect(@dance.created_at).not_to be_nil
      end

      subject {
        id = connection.update another_model_class, @dance.id, :person_id => @dance.person_id, :title => "Hobby", :created_at => @dance.created_at, :updated_at => @dance.updated_at
        another_model_class.find_by_id id
      }

      # XXX: updated_at should change
      its(:updated_at) {
        should be_within(2).of(Time.now)
        should_not eql @dance.updated_at
      }

      its(:created_at) {
        should eql @dance.created_at
      }
    end
  end

  # describe "#update many" do
  #   it "should available and countup with auto increment" do
  #     id = nil

  #     auto_increment = model_class.connection.__send__(:select, <<-SQL).to_a.first["AUTO_INCREMENT"]
# SELECT AUTO_INCREMENT
# FROM   INFORMATION_SCHEMA.TABLES
# WHERE  TABLE_SCHEMA = '#{model_class.configurations[RAILS_ENV][:database]}'
# AND    TABLE_NAME = '#{model_class.table_name}'
  #     SQL

  #     10000.times do |i|
  #       id = connection.insert model_class, :name => "Name#{i}", :age => i, :status => rand(2).zero?
  #     end

  #     expect(id).to == model_class.last.id
  #     expect(id).to == auto_increment - 1 + 10000
  #   end
  # end













  describe "#current_time_from_proper_timezone" do
    before :each do
      @default = model_class.default_timezone
    end

    after :each do
      model_class.default_timezone = @default
    end

    context "with utc timezone" do
      before :each do
        model_class.default_timezone = :utc
      end

      subject { connection.current_time_from_proper_timezone }

      it { should == Time.now.utc.to_s(:db) }
    end

    context "with local timezone" do
      before :each do
        model_class.default_timezone = :local
      end

      subject { connection.current_time_from_proper_timezone }

      it { should == Time.now.to_s(:db) }
    end
  end

  describe "#to_a_write_values" do
    describe "attributes to array" do
      subject { connection.to_a_write_values({:A => 1, :B => "b"}, ["A", "B"]) }
      it { should == [1, "b"] }
    end

    describe "attributes to reverse array" do
      subject { connection.to_a_write_values({:A => 1, :B => "b"}, ["B", "A"]) }
      it { should == ["b", 1] }
    end

    context "when true given" do
      subject { connection.to_a_write_values({:C => true}, ["C"]) }
      it { should == [1] }
    end

    context "when true given" do
      subject { connection.to_a_write_values({:C => false}, ["C"]) }
      it { should == [0] }
    end

    context "when nil given" do
      subject { connection.to_a_write_values({:D => nil}, ["D"]) }
      it { should == [nil] }
    end

    context "when time given" do
      let(:now) { Time.now }

      subject { connection.to_a_write_values({:E => now}, ["E"]) }

      it { should == [now.to_s(:db)] }
    end

    context "when time given" do
      let(:today) { Date.today }

      subject { connection.to_a_write_values({:E => today}, ["E"]) }

      it { should == [today.to_s(:db)] }
    end

    context "when timestamp field is nil" do
      before :each do
        @default = model_class.default_timezone
        model_class.default_timezone = :local
      end

      after :each do
        model_class.default_timezone = @default
      end

      describe "add timestamps" do
        let(:now) { Time.now }

        subject { connection.to_a_write_values({}, ["updated_at", "created_at", "updated_on", "created_on"]) }

        it { should == [now.to_s(:db), now.to_s(:db), now.to_s(:db), now.to_s(:db)] }
      end

      describe "add timestamps except existing" do
        let(:now)        { Time.now }
        let(:created_at) { now - 1 }

        subject { connection.to_a_write_values({:created_at => created_at, :created_on => created_at}, ["updated_at", "created_at", "updated_on", "created_on"]) }

        it { should == [now.to_s(:db), created_at.to_s(:db), now.to_s(:db), created_at.to_s(:db)] }
      end
    end

    context "when less fields" do
      subject { connection.to_a_write_values({:X => 1, :Y => 2, :Z => 3}, ["X", "Z"]) }

      it { should == [1, 3] }
    end

    context "when more fields" do
      subject { connection.to_a_write_values({:X => 1, :Y => 2, :Z => 3}, ["W", "X", "Y", "Z"]) }

      it { should == [nil, 1, 2, 3] }
    end
  end

  describe "#write_result" do
    subject { connection.write_result [0, [["10"]]] }

    it { should == 10 }

    context "when error signal 121 given" do
      it "should raise error for duplicate entry" do
        expect{
          connection.write_result [1, "121"]
        }.to raise_error ArgumentError
      end

      it "should raise error has message for duplicate entry" do
        message = nil

        begin
          connection.write_result [1, "121"]
        rescue ArgumentError => e
          message = e.message
        end

        expect(message).to match(/duplicate entry/)
      end
    end

    context "when another error given" do
      it "should raise error for duplicate entry" do
        expect{
          connection.write_result [1, "stmtnum"]
        }.to raise_error(ArgumentError)
      end
    end

    context "when connection error" do
      before :each do
        connection.reconnect!

        connection.select model_class, :first, :id, [1]
        connection.select model_class, :first, :age_and_status, [36, 0]

        connection.select another_model_class, :first, :id, [1]

        connection.insert model_class, :name => "Test", :age => 24, :status => true

        connection.insert another_model_class,  :person_id => 1, :title => "Test"
      end

      after :each do
        connection.reconnect!
      end

      it "should raise error for connection loat" do
        expect{
          connection.write_result [-1, "write: closed"]
        }.to raise_error ActiveRecordHandlerSocket::ConnectionLost
      end

      it "should all indexes closed" do
        expect(connection.indexes.map{|k, setting| setting[:opened] }.any?).to be

        begin
          connection.write_result [-1, "write: closed"]
        rescue
        end

        expect(connection.indexes.map{|k, setting| !setting[:opened] }.all?).to be
      end
    end
  end
end

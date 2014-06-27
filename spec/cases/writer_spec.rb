require 'spec_helper'

describe "WriterSpec" do
  let :klass do
    Person
  end

  let :another_klass do
    Hobby
  end

  before :each do
    @bob      = FactoryGirl.create(:bob)
    @pharrell = FactoryGirl.create(:pharrell)
    @john     = FactoryGirl.create(:john)

    klass.__send__ :hs_writer
  end

  describe "hscreate" do
    before :each do
      klass.delete_all
      another_klass.delete_all
    end

    context "with given attributes" do
      it "should callable" do
        id = klass.hscreate :name => "Test", :age => 24, :status => true
        record = klass.find_by_id id

        expect(record.name).to eql("Test")
        expect(record.age).to eql(24)
        expect(record.status).to eql(true)
      end

      # After handlersocket version up (over 0.0.2) nil will be supported.
      it "should callable but having nil" do
        expect{
          id = klass.hscreate :name => "Test", :age => 24, :status => nil
        }.to raise_error(TypeError)
      end
    end

    context "with unique index" do
      it "should saved first time" do
        id = another_klass.hscreate :person_id => 1, :title => "Hobby"
        record = another_klass.find_by_id id

        expect(record.person_id).to eql(1)
        expect(record.title).to eql("Hobby")
      end

      it "should raise error" do
        another_klass.hscreate :person_id => 1, :title => "Hobby"

        expect{
          another_klass.hscreate :person_id => 1, :title => "Hobby"
        }.to raise_error(ArgumentError)
      end
    end

    context "with timestamp" do
      it "should fill updated_at" do
        id = another_klass.hscreate :person_id => 1, :title => "Hobby"

        record = another_klass.find_by_id id

        expect(record.updated_at).to be_within(2).of(Time.now)
      end

      it "should fill created_at" do
        id = another_klass.hscreate :person_id => 1, :title => "Hobby"

        record = another_klass.find_by_id id

        expect(record.updated_at).to be_within(2).of(Time.now)
      end
    end

  end

  describe "hscreate many" do
    it "should available and countup with auto increment" do
      id = nil

      auto_increment = klass.connection.__send__(:select, <<-SQL).to_a.first["AUTO_INCREMENT"]
SELECT AUTO_INCREMENT
FROM   INFORMATION_SCHEMA.TABLES
WHERE  TABLE_SCHEMA = '#{klass.configurations[RAILS_ENV][:database]}'
AND    TABLE_NAME = '#{klass.table_name}'
      SQL

      10000.times do |i|
        id = klass.hscreate :name => "Name#{i}", :age => i, :status => rand(2)
      end

      expect(id).to eql(klass.last.id)
      expect(id).to eql(auto_increment - 1 + 10000)
    end
  end

  describe "hs_current_time_from_proper_timezone" do
    before :each do
      @default = klass.default_timezone
    end

    after :each do
      klass.default_timezone = @default
    end

    it "should return utc time" do
      klass.default_timezone = :utc

      expect(klass.__send__(:hs_current_time_from_proper_timezone)).to eql(Time.now.utc.to_s(:db))
    end

    it "should return local time" do
      klass.default_timezone = :local

      expect(klass.__send__(:hs_current_time_from_proper_timezone)).to eql(Time.now.to_s(:db))
    end
  end

  describe "hs_to_a_write_values" do
    it "should attributes to array" do
      values = klass.__send__ :hs_to_a_write_values, {:A => 1, :B => "b"}, ["A", "B"]
      expect(values).to eql([1, "b"])

      values = klass.__send__ :hs_to_a_write_values, {:A => 1, :B => "b"}, ["B", "A"]
      expect(values).to eql(["b", 1])
    end

    context "when boolean given" do
      it "should convert true to 1" do
        values = klass.__send__ :hs_to_a_write_values, {:C => true}, ["C"]
        expect(values).to eql([1])
      end

      it "should convert false to 0" do
        values = klass.__send__ :hs_to_a_write_values, {:C => false}, ["C"]
        expect(values).to eql([0])
      end
    end

    context "when nil given" do
      it "should not convert" do
        values = klass.__send__ :hs_to_a_write_values, {:D => nil}, ["D"]
        expect(values).to eql([nil])
      end
    end

    context "when time given" do
      it "should convert db format string" do
        t = Time.now
        values = klass.__send__ :hs_to_a_write_values, {:E => t}, ["E"]
        expect(values).to eql([t.to_s(:db)])
      end
    end

    context "when date given" do
      it "should convert db format string" do
        d = Date.today
        values = klass.__send__ :hs_to_a_write_values, {:F => d}, ["F"]
        expect(values).to eql([d.to_s(:db)])
      end
    end

    context "when timestamp field is nil" do
      it "should add timestamp" do
        t = Time.now
        values = klass.__send__ :hs_to_a_write_values, {}, ["updated_at", "created_at"]
        expect(values).to eql([t.to_s(:db), t.to_s(:db)])

        values = klass.__send__ :hs_to_a_write_values, {}, ["updated_on", "created_on"]
        expect(values).to eql([t.to_s(:db), t.to_s(:db)])
      end

      it "should not fill for exist field" do
        c = Time.now - 1
        t = Time.now
        expect(c.to_s(:db)).not_to eql(t.to_s(:db))

        values = klass.__send__ :hs_to_a_write_values, {:created_at => c}, ["updated_at", "created_at"]
        expect(values).to eql([t.to_s(:db), c.to_s(:db)])

        values = klass.__send__ :hs_to_a_write_values, {:created_on => c}, ["updated_on", "created_on"]
        expect(values).to eql([t.to_s(:db), c.to_s(:db)])
      end
    end

    context "when less fields" do
      it "should fit to given fields" do
        values = klass.__send__ :hs_to_a_write_values, {:X => 1, :Y => 2, :Z => 3}, ["X", "Z"]
        expect(values).to eql([1, 3])
      end
    end

    context "when more fields" do
      it "should fit to given fields" do
        values = klass.__send__ :hs_to_a_write_values, {:X => 1, :Y => 2, :Z => 3}, ["W", "X", "Y", "Z"]
        expect(values).to eql([nil, 1, 2, 3])
      end
    end
  end

  describe "hs_write_result" do
    it "should return result number" do
      number = klass.__send__ :hs_write_result, [0, [["10"]]]
      expect(number).to eql(10)
    end

    context "when error signal 121 given" do
      it "should raise error for duplicate entry" do
        expect{
          klass.__send__ :hs_write_result, [1, "121"]
        }.to raise_error(ArgumentError)
      end

      it "should raise error has message for duplicate entry" do
        message = nil

        begin
          klass.__send__ :hs_write_result, [1, "121"]
        rescue ArgumentError => e
          message = e.message
        end

        expect(message).to match(/duplicate entry/)
      end
    end

    context "when another error given" do
      it "should raise error for duplicate entry" do
        expect{
          klass.__send__ :hs_write_result, [1, "stmtnum"]
        }.to raise_error(ArgumentError)
      end
    end

    context "when connection error" do
      before :each do
        ActiveRecord::Base.hs_reconnect!

        klass.hsfind_by_id 1
        klass.hsfind_by_age_and_status 36, 0

        another_klass.hsfind_by_id 1

        klass.hscreate :name => "Test", :age => 24, :status => true

        another_klass.hscreate :person_id => 1, :title => "Test"
      end

      after :each do
        ActiveRecord::Base.hs_reconnect!
      end

      it "should raise error for connection loat" do
        expect{
          klass.__send__ :hs_write_result, [-1, "write: closed"]
        }.to raise_error(ActiveRecordHandlerSocket::CannotConnectError)
      end

      it "should all indexes closed" do
        expect( ActiveRecord::Base.__send__(:hs_indexes).map{|k, setting| setting[:opened] }.any? ).to be

        begin
          klass.__send__ :hs_write_result, [-1, "write: closed"]
        rescue
        end

        expect( ActiveRecord::Base.__send__(:hs_indexes).map{|k, setting| !setting[:opened] }.all? ).to be
      end
    end
  end
end

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

  describe "#hscreate" do
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

  describe "#hscreate many" do
    it "should available and countup with auto increment" do
      id = nil

      auto_increment = klass.connection.select(<<-SQL).rows.first.first
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
end

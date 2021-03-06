require 'spec_helper'

describe ActiveRecord::Base do
  let :model_class do
    Person
  end

  let :another_model_class do
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
          index_key = connection.index_key model_class, :id
          setting   = connection.fetch index_key
          setting[:fields]
        }
        it { should eql %W[id name age status] }
      end

      describe "Hobby:id" do
        subject {
          index_key = connection.index_key another_model_class, :id
          setting = connection.fetch index_key
          setting[:fields]
        }
        it { should eql %W[id person_id title] }
      end
    end

    context "when columns options" do
      before :each do
        model_class.hs_reader :test, "PRIMARY", :columns => %W[id name]
      end

      subject {
        index_key = connection.index_key model_class, :test
        setting = connection.fetch index_key
        setting[:fields]
      }
      it { should eql %W[id name] }
    end
  end

  describe ".hs_writer" do
    context "when same key from another model" do
      describe "Person:__writer__" do
        subject {
          index_key = connection.index_writer_key model_class
          setting = connection.fetch index_key
          setting[:fields]
        }
        it { should eql %W[name age status] }
      end

      describe "Hobby:__writer__" do
        subject {
          index_key = connection.index_writer_key another_model_class
          setting = connection.fetch index_key
          setting[:fields]
        }
        it { should eql %W[person_id title created_at updated_at] }
      end
    end

    context "when columns options" do
      before :each do
        model_class.hs_writer :columns => %W[id name]
      end

      subject {
        index_key = connection.index_writer_key model_class
        setting = connection.fetch index_key
        setting[:fields]
      }
      it { should eql %W[name] }
    end

    describe "index fixed" do
      subject {
        index_key = connection.index_writer_key model_class
        setting = connection.fetch index_key
        setting[:index]
      }
      it { should eql "PRIMARY" }
    end
  end

  describe ".method_missing" do
    context "default behavior" do
      describe "find_by_id" do
        subject { model_class.find_by_id 1 }
        it      { should eql @bob }
      end

      describe "find_by_age_and_status" do
        subject { model_class.find_by_age_and_status 36, true }
        it      { should eql @john }
      end
    end

    context "call .hsfind_by_xxx" do
      describe "for id" do
        subject { model_class.hsfind_by_id 1 }
        it      { should eql @bob }
      end

      # XXX: hsfind with true/false
      describe "for age_and_status" do
        subject { model_class.hsfind_by_age_and_status 36, 1 }
        it      { should eql @john }
      end
    end

    context "call .hsfind_multi_by_xxx" do
      describe "for id" do
        subject { model_class.hsfind_multi_by_id 1, 3 }
        it      { should eql [@bob, @john] }
      end

      # XXX: hsfind with true/false
      describe "for age_and_status" do
        subject { model_class.hsfind_multi_by_age_and_status [36, 1] }
        it      { should eql [@john] }
      end
    end
  end

  describe ".hsfind" do
    context "for :first" do
      context "when found record" do
        subject { model_class.hsfind :first, :id, [1] }
        it      { should eql @bob }
      end

      context "when not found" do
        subject { model_class.hsfind :first, :id, [0] }
        it      { should be_nil }
      end
    end

    context "for :multi" do
      context "when found records" do
        subject { model_class.hsfind :multi, :id, [1, 2] }
        it      { should eql [@bob, @pharrell] }
      end

      context "when partial found" do
        subject { model_class.hsfind :multi, :id, [0, 1] }
        it      { should eql [@bob] }
      end

      context "when not found" do
        subject { model_class.hsfind :multi, :id, [0, -1] }
        it      { should be_empty }
      end
    end

    context "for :unknown" do
      subject { lambda { model_class.hsfind :unknown, :id, [1] } }
      it      { should raise_error ArgumentError }
    end

    context "unknown key given" do
      subject { lambda { model_class.hsfind :first, :unknown, [1] } }
      it      { should raise_error ActiveRecordHandlerSocket::UnknownIndexError }
    end

    context "args empty" do
      subject { lambda { model_class.hsfind :first, :id, [] } }
      it      { should raise_error ArgumentError }
    end
  end

  describe ".hscreate" do
    before :each do
      model_class.hs_writer
      Hobby.hs_writer
    end

    describe "return value" do
      before :each do
        @auto_increment = model_class.connection.__send__(:select, <<-SQL).to_a.first["AUTO_INCREMENT"]
SELECT AUTO_INCREMENT
FROM   INFORMATION_SCHEMA.TABLES
WHERE  TABLE_SCHEMA = '#{model_class.configurations[RAILS_ENV][:database]}'
AND    TABLE_NAME = '#{model_class.table_name}'
        SQL
      end

      subject { model_class.hscreate :name => "Test", :age => 24, :status => true }
      it      { should eql @auto_increment }
    end

    describe "Person created" do
      before :each do
        @id = model_class.hscreate :name => "Test", :age => 24, :status => true
      end

      subject      { model_class.find_by_id @id }
      its(:name)   { should eql "Test" }
      its(:age)    { should eql 24 }
      its(:status) { should be true }
    end

    describe "Hobby created" do
      before :each do
        @id = another_model_class.hscreate :person_id => 1, :title => "Test"
      end

      subject          { another_model_class.find_by_id @id }
      its(:person_id)  { should eql 1 }
      its(:title)      { should eql "Test" }
      its(:created_at) { should be_within(2).of(Time.now) }
      its(:updated_at) { should be_within(2).of(Time.now) }
    end
  end

  describe ".hsupdate" do
    before :each do
      model_class.hs_writer
      another_model_class.hs_writer
    end

    describe "return value" do
      subject { model_class.hsupdate 2, :name => "Test", :age => 24, :status => true }
      it      { should eql 2 }
    end

    describe "Person updated" do
      before :each do
        model_class.hsupdate 2, :name => "Test", :age => 24, :status => true
      end

      subject      { model_class.find_by_id 2 }
      its(:name)   { should eql "Test" }
      its(:age)    { should eql 24 }
      its(:status) { should be true }
    end

    describe "Hobby updated" do
      before :each do
        FactoryGirl.create :dance
        @time = Time.now - 1.day
        another_model_class.hsupdate 1, :person_id => 1, :title => "Test", :created_at => @time
      end

      subject          { another_model_class.find_by_id 1 }
      its(:person_id)  { should eql 1 }
      its(:title)      { should eql "Test" }
      its(:created_at) { should_not be_within(2).of(Time.now) }
      its(:updated_at) { should be_within(2).of(Time.now) }
    end
  end

  describe ".hsdelete" do
    before :each do
      model_class.hs_writer
      another_model_class.hs_writer
    end

    describe "return value" do
      subject { model_class.hsdelete 2 }
      it      { should eql 2 }
    end

    describe "Person deleted" do
      before :each do
        model_class.hsdelete 2
      end

      subject { model_class.find_by_id 2 }
      it      { should be_nil }
    end

    describe "Hobby deleted" do
      before :each do
        FactoryGirl.create :dance
        another_model_class.hsdelete 1
      end

      subject { another_model_class.find_by_id 1 }
      it      { should be_nil }
    end
  end

  describe "#hssave" do
    context "for new record" do
      before :each do
        @record = model_class.new :name => "Test", :age => 25, :status => true
      end

      it "should return true" do
        expect(@record.hssave).to be true
        expect(@record.new_record?).to be false
      end
    end

    context "for existing record" do
      before :all do
        @dance = FactoryGirl.create :dance
        @dance.title = "Hoge"
        @old_updated_at = @dance.updated_at
        sleep 1
      end

      subject { @dance.hssave }
      it      { should be true }
    end

    context "updated value" do
      before :all do
        @dance = FactoryGirl.create :dance
        @dance.reload
        @dance.title = "Hoge"
        @old_updated_at = @dance.updated_at
        sleep 2
        @dance.hssave
      end

      subject { @dance }
      its(:title)      { should eql "Hoge" }
      its(:updated_at) { should_not eql @old_updated_at }
      its(:created_at) { should eql @old_updated_at }
    end
  end

  describe "#hscreate" do
    before :each do
      @record = another_model_class.new :title => "Test", :person_id => 1
    end

    context "returned value" do
      subject { @record.hscreate }
      it      { should be true }
    end

    context "do validation" do
      before :each do
        @record = model_class.new :name => "Test", :age => 25, :status => true
        @record.hscreate
      end

      subject           { @record }
      its(:new_record?) { should be false }
      its(:errors)      { should be_empty }
    end

    context "invalid record" do
      before :each do
        @record = model_class.new :name => "Test", :age => 25, :status => nil
        @record.hscreate
      end

      subject           { @record }
      its(:new_record?) { should be true }
      its(:errors)      { should_not be_empty }
    end

    context "work before_create callback" do
      before :each do
        @record.hscreate
      end

      subject                { @record.callback_called }
      its([:before_create])  { should be true }
      its([:before_update])  { should be_nil }
      its([:before_destroy]) { should be_nil }
    end

    context "stop on before_create callback" do
      before :each do
        stub_object @record, :before_create_callback, false

        @record.hscreate
      end

      subject           { @record }
      its(:new_record?) { should be true }
      its(:errors)      { should be_empty }
    end

    context "work after_create callback" do
      before :each do
        @record.hscreate
      end

      subject               { @record.callback_called }
      its([:after_create])  { should be true }
      its([:after_update])  { should be_nil }
      its([:after_destroy]) { should be_nil }
    end

    context "add timestamps" do
      before :each do
        @record.hscreate
      end

      subject          { @record }
      its(:created_at) { should_not be_nil }
      its(:updated_at) { should_not be_nil }
    end
  end

  describe "#hsudpate" do
    before :each do
      @record = another_model_class.new :title => "Test", :person_id => 1
      @record.save
      @record.callback_called = nil
      @record.title = "Update"
    end

    context "returned value" do
      subject { @record.hsupdate }
      it      { should be true }
    end

    context "do validation" do
      before :each do
        @record = model_class.new :name => "Test", :age => 25, :status => true
        @record.save
        @record.status = false
        @record.hsupdate
      end

      subject               { @record }
      its(:status_changed?) { should be false }
      its(:errors)          { should be_empty }
    end

    context "invalid record" do
      before :each do
        @record = model_class.new :name => "Test", :age => 25, :status => true
        @record.save
        @record.status = nil
        @record.hsupdate
      end

      subject               { @record }
      its(:status_changed?) { should be true }
      its(:errors)          { should_not be_empty }
    end

    context "work before_update callback" do
      before :each do
        @record.hsupdate
      end

      subject                { @record.callback_called }
      its([:before_create])  { should be_nil }
      its([:before_update])  { should be true }
      its([:before_destroy]) { should be_nil }
    end

    context "stop on before_update callback" do
      before :each do
        stub_object @record, :before_update_callback, false

        @record.hsupdate
      end

      subject              { @record }
      its(:title_changed?) { should be true }
      its(:errors)         { should be_empty }
    end

    context "work after_update callback" do
      before :each do
        @record.hsupdate
      end

      subject               { @record.callback_called }
      its([:after_create])  { should be_nil }
      its([:after_update])  { should be true }
      its([:after_destroy]) { should be_nil }
    end

    context "add timestamps" do
      before :each do
        @old_created_at = @record.created_at
        @old_updated_at = @record.updated_at
        @record.hsupdate
      end

      subject          { @record }
      its(:created_at) { should eql @old_created_at }
      its(:updated_at) { should_not eql @old_updated_at }
    end
  end

  describe "hsdestroy" do
    before :each do
      @record = another_model_class.new :title => "Test", :person_id => 1
      @record.save
      @record.callback_called = nil
    end

    context "returned value" do
      subject { @record.hsdestroy }
      it      { should be true }
    end

    context "work before_destroy callback" do
      before :each do
        @record.hsdestroy
      end

      subject                { @record.callback_called }
      its([:before_create])  { should be_nil }
      its([:before_update])  { should be_nil }
      its([:before_destroy]) { should be true }
    end

    context "stop on before_destroy callback" do
      before :each do
        stub_object @record, :before_destroy_callback, false

        @record.hsdestroy
      end

      subject { @record.reload }
      it      { should be } # truthy
    end

    context "work after_destroy callback" do
      before :each do
        @record.hsdestroy
      end

      subject               { @record.callback_called }
      its([:after_create])  { should be_nil }
      its([:after_update])  { should be_nil }
      its([:after_destroy]) { should be true }
    end
  end
end

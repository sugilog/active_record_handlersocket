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

  let :logger do
    ActiveRecord::Base.logger
  end

  let! :connection do
    klass.establish_connection ActiveRecord::Base.logger
  end

  describe ".establish_connection" do
    context "without options" do
      subject { connection }

      it { should be_kind_of klass }
      its(:logger)      { should eql ActiveRecord::Base.logger }
      its(:model_class) { should eql ActiveRecord::Base }
      its(:indexes)     { should be_blank }
      its(:indexes)     { should be_kind_of Hash }
      its(:index_count_cache) { should eql 0 }

      describe ".connections" do
        subject { connection.connections }
        its([:read])  { should be_kind_of HandlerSocket }
        its([:write]) { should be_kind_of HandlerSocket }
      end
    end

    context "with model_class option" do
      before :each do
        @connection = klass.establish_connection logger, :model_class => model_class
      end

      describe ".model_class" do
        subject { @connection.model_class }

        it { should eql model_class }
      end
    end
  end

  describe "#initialize" do
    context "without options" do
      before :each do
        @connection = klass.new logger
      end

      subject { @connection }

      it { should be_kind_of klass }
      its(:logger)      { should eql ActiveRecord::Base.logger }
      its(:model_class) { should eql ActiveRecord::Base }
      its(:indexes)     { should be_blank }
      its(:indexes)     { should be_kind_of Hash }
      its(:index_count_cache) { should eql 0 }

      describe ".connections" do
        subject { @connection.connections }

        its([:read])  { should be_nil }
        its([:write]) { should be_nil }
      end
    end

    context "with model_class option" do
      before :each do
        @connection = klass.new logger, :model_class => model_class
      end

      subject { @connection }

      its(:model_class) { should eql model_class }
    end
  end

  describe "#establish_connection" do
    before :each do
      @connection = klass.new logger
    end

    context "before establish for read" do
      subject { @connection.connections[:read] }

      it { should be_nil }
    end

    context "before establish for write" do
      subject { @connection.connections[:write] }

      it { should be_nil }
    end

    context "with read" do
      before :each do
        connection.establish_connection :read
      end

      subject { connection.read_connection }

      it { should be_kind_of HandlerSocket }

      describe ":@current_config" do
        subject { connection.read_connection.instance_variable_get(:@_current_config) }

        it "should have current_config" do
          config = connection.connection_config :read
          config = config.slice :host, :port

          should eql config
        end
      end
    end

    context "with write" do
      before :each do
        connection.establish_connection :write
      end

      subject { connection.write_connection }

      it { should be_kind_of HandlerSocket }

      describe ":@current_config" do
        subject { connection.write_connection.instance_variable_get(:@_current_config) }

        it "should have current_config" do
          config = connection.connection_config :write
          config = config.slice :host, :port

          should eql config
        end
      end
    end

    context "with unknown" do
      it { 
        expect {
          connection.establish_connection :unknown
        }.to raise_error ArgumentError
      }
    end
  end

  describe "#read_connection" do
    subject { connection.read_connection }

    it { should be_kind_of HandlerSocket }
  end

  describe "#write_connection" do
    subject { connection.write_connection }

    it { should be_kind_of HandlerSocket }
  end

  describe "#reconnect!" do
    before :each do
      add_index_setting connection

      connection.read_connection.close
      connection.write_connection.close

      connection.reset_opened_indexes
    end

    subject { connection.reconnect! }

    it { should be }

    context "then find" do
      before :each do
        FactoryGirl.create(:bob)
        connection.reconnect!
        stub_object model_class, :hs_connection,  connection
      end

      subject { model_class.hsfind_by_id 1 }

      it "should found" do
        should be_kind_of model_class
      end
    end

    context "then create" do
      before :each do
        connection.reconnect!
        stub_object model_class, :hs_connection, connection
      end

      subject {
        id = model_class.hscreate :name => "Test", :age => 24, :status => true
        model_class.hsfind_by_id id
      }

      it "should created" do
        should be_kind_of model_class
      end
    end

    context "then index_setting for read" do
      before :each do
        connection.reconnect!
      end

      subject {
        index_key = connection.index_key model_class, :id
        setting   = connection.fetch index_key
        setting[:opened]
      }

      it "should setting reset" do
        expect(subject).not_to be
      end
    end

    context "then index_setting for write" do
      before :each do
        connection.reconnect!
      end

      subject {
        index_key = connection.index_writer_key model_class
        setting   = connection.fetch index_key
        setting[:opened]
      }

      it "should setting reset" do
        expect(subject).not_to be
      end
    end
  end

  describe "#acitve?" do
    before :each do
      add_index_setting connection
    end

    context "when connected" do
      subject { connection.active? }

      it "should return true" do
        should be
      end
    end

    context "when read closed" do
      subject { connection.active? }

      before :each do
        connection.read_connection.close
      end

      it "should return false" do
        expect(subject).not_to be
      end
    end

    context "when write closed" do
      subject { connection.active? }

      before :each do
        # open index
        connection.write_connection.close
      end

      it "should return false" do
        expect(subject).not_to be
      end
    end
  end

  describe "#open_index" do
    before :each do
      add_index_setting connection
    end

    context "when index opened" do
      subject {
        index_key = connection.index_key model_class, :id
        connection.open_index model_class, index_key
      }

      it { should be_nil }
    end

    context "when open index" do
      before :each do
        connection.reconnect!
      end

      describe "return value" do
        subject {
          index_key = connection.index_key model_class, :id
          connection.open_index model_class, index_key
        }

        it { should be }
      end

      describe "before opened" do
        subject {
          index_key = connection.index_key model_class, :id
          setting = connection.fetch index_key
          setting[:opened]
        }

        it { expect(subject).not_to be }
      end

      describe "marked index setting opened" do
        before :each do
          index_key = connection.index_key model_class, :id
          connection.open_index model_class, index_key
        end

        subject {
          index_key = connection.index_key model_class, :id
          setting = connection.fetch index_key
          setting[:opened]
        }

        it { should be }
      end
    end

    context "when open write index" do
      before :each do
        connection.reconnect!
      end

      describe "return value" do
        subject {
          index_key = connection.index_writer_key model_class
          connection.open_index model_class, index_key, :write
        }

        it { should be }
      end

      describe "before opened" do
        subject {
          index_key = connection.index_writer_key model_class
          setting = connection.fetch index_key
          setting[:opened]
        }

        it { expect(subject).not_to be }
      end

      describe "marked index setting opened" do
        subject {
          index_key = connection.index_writer_key model_class
          connection.open_index model_class, index_key, :write
          setting = connection.fetch index_key
          setting[:opened]
        }

        it { should be }
      end
    end

    context "when invalid result" do
      before :each do
        stub_object connection.read_connection, :open_index, 2
        stub_object connection.read_connection, :error,      "err"

        connection.reconnect!
      end

      it "should raise ArgumentError" do
        index_key = connection.index_key model_class, :id

        expect {
          connection.open_index model_class, index_key
        }.to raise_error ArgumentError
      end

      describe "index setting for Person:id" do
        before :each do
          begin
            index_key = connection.index_key model_class, :id
            connection.open_index model_class, index_key
          rescue ArgumentError
          end
        end

        subject {
          index_key = connection.index_key model_class, :id
          setting = connection.fetch index_key
          setting[:opened]
        }

        it { expect(subject).not_to be }
      end

      describe "index setting for Hobby:id" do
        before :each do
          index_key = connection.index_key another_model_class, :id
          setting = connection.fetch index_key
          setting[:opened] = true

          begin
            index_key = connection.index_key model_class, :id
            connection.open_index model_class, index_key
          rescue ArgumentError
          end
        end

        subject {
          index_key = connection.index_key another_model_class, :id
          setting = connection.fetch index_key
          setting[:opened]
        }

        it { should be }
      end
    end

    context "when connection error" do
      before :each do
        stub_object connection.read_connection, :open_index, -1
        stub_object connection.read_connection, :error,      "connection lost"

        connection.reconnect!
      end

      it "should raise CannotConnectionError" do
        index_key = connection.index_key model_class, :id

        expect{
          connection.open_index model_class, index_key
        }.to raise_error ActiveRecordHandlerSocket::CannotConnectError
      end

      describe "index setting for Person:id" do
        before :each do
          begin
            index_key = connection.index_key model_class, :id
            connection.open_index model_class, index_key
          rescue ActiveRecordHandlerSocket::CannotConnectError
          end
        end

        subject {
          index_key = connection.index_key model_class, :id
          setting = connection.fetch index_key
          setting[:opened]
        }

        it { expect(subject).not_to be }
      end

      describe "index setting for Hobby:id" do
        before :each do
          index_key = connection.index_key another_model_class, :id
          setting = connection.fetch index_key
          setting[:opened] = true

          begin
            index_key = connection.index_key model_class, :id
            connection.open_index model_class, index_key
          rescue ActiveRecordHandlerSocket::CannotConnectError
          end
        end

        subject {
          index_key = connection.index_key another_model_class, :id
          setting = connection.fetch index_key
          setting[:opened]
        }

        it { expect(subject).not_to be }
      end
    end
  end

  describe "#connection_config" do
    context :read do
      subject { connection.connection_config :read }

      it { should eql ActiveRecord::Base.configurations["#{RAILS_ENV}_hs_read"].symbolize_keys }
    end

    context :write do
      subject { connection.connection_config :write }

      it { should eql ActiveRecord::Base.configurations["#{RAILS_ENV}_hs_write"].symbolize_keys }
    end
  end

  describe "#index_count" do
    let :initial_count do
      connection.index_count_cache
    end

    it "should increment" do
      # initialize
      initial_count

      expect(connection.index_count).to eql initial_count + 1
      expect(connection.index_count).to eql initial_count + 2
      expect(connection.index_count).to eql initial_count + 3
    end
  end

  describe "#reset_opened_indexes" do
    before :each do
      add_index_setting connection
    end

    context "before reset" do
      describe "for Person:id" do
        subject {
          index_key = connection.index_key model_class, :id
          connection.indexes[index_key][:opened]
        }

        it { should be }
      end

      describe "for Hobby:id" do
        subject {
          index_key = connection.index_key another_model_class, :id
          connection.indexes[index_key][:opened]
        }

        it { should be }
      end
    end

    context "after reset" do
      before :each do
        connection.reset_opened_indexes
      end

      describe "for Person:id" do
        subject {
          index_key = connection.index_key model_class, :id
          connection.indexes[index_key][:opened]
        }

        it { expect(subject).not_to be }
      end

      describe "for Hobby:id" do
        subject {
          index_key = connection.index_key another_model_class, :id
          connection.indexes[index_key][:opened]
        }

        it { expect(subject).not_to be }
      end
    end
  end

  describe "#add_index_setting" do
    let :index_name do
      "index_people_on_age_and_status"
    end

    let :key do
      :age_and_status
    end

    let :index_key do
      connection.index_key model_class, key
    end

    subject { connection.add_index_setting model_class, key, index_name }

    it "returns index_key" do
      should eql index_key
    end

    context "with columns" do
      before :each do
        @initial_count = connection.index_count_cache
        connection.add_index_setting model_class, key, index_name, :columns => %W[id name age]
      end

      let :setting do
        {
          :id     => @initial_count + 1,
          :index  => index_name,
          :fields => %W[id name age],
          :opened => false
        }
      end

      subject { connection.fetch index_key }

      it { should eql setting }

      context "with write option" do
        before :each do
          @initial_count = connection.index_count_cache
          connection.add_index_setting model_class, key, index_name, :columns => %W[id name age], :write => true
        end

        let :setting do
          {
            :id     => @initial_count + 1,
            :index  => index_name,
            :fields => %W[name age],
            :opened => false
          }
        end

        subject { connection.fetch index_key }

        it { should eql setting }
      end

      context "with empty columns" do
        before :each do
          @initial_count = connection.index_count_cache
        end

        it do
          expect{
            connection.add_index_setting model_class, key, index_name, :columns => []
          }.to raise_error ArgumentError
        end
      end

      context "with writer specified columns only id" do
        before :each do
          @initial_count = connection.index_count_cache
        end

        it do
          expect{
            connection.add_index_setting model_class, key, index_name, :columns => [:id], :write => true
          }.to raise_error ArgumentError
        end
      end
    end

    context "without columns" do
      before :each do
        @initial_count = connection.index_count_cache
        connection.add_index_setting model_class, key, index_name
      end

      let :setting do
        {
          :id     => @initial_count + 1,
          :index  => index_name,
          :fields => %W[id name age status],
          :opened => false
        }
      end

      subject { connection.fetch index_key }

      it { should eql setting }

      context "with write option" do
        before :each do
          @initial_count = connection.index_count_cache
          connection.add_index_setting model_class, key, index_name, :write => true
        end

        let :setting do
          {
            :id     => @initial_count + 1,
            :index  => index_name,
            :fields => %W[name age status],
            :opened => false
          }
        end

        subject { connection.fetch index_key }

        it { should eql setting }
      end
    end

    context "when existing setting overwrite" do
      before :each do
        connection.add_index_setting model_class, key, index_name
        connection.add_index_setting model_class, key, index_name
      end

      subject {
        warning_log.rewind
        warned = warning_log.read.chomp
      }

      it { should match(/ActiveRecordHandlerSocket: #{index_key} was updated/) }
    end

    context "when multi-time call" do
      before :each do
        @first_index_key  = connection.add_index_setting model_class, :first,  index_name
        @second_index_key = connection.add_index_setting model_class, :second, index_name
      end

      subject {
        first_setting = connection.fetch @first_index_key
        first_setting[:id]
      }

      it "should increment" do
        second_setting = connection.fetch @second_index_key
        should eql second_setting[:id] - 1
      end
    end
  end

  describe "#index_key" do
    subject { connection.index_key model_class, :id }

    it { should eql [ model_class, :id ].join(":") }
  end

  describe "#index_writer_key" do
    subject { connection.index_writer_key model_class }

    it { should eql [ model_class, klass::WRITER_KEY ].join(":") }
  end

  describe "#fetch" do
    before :each do
      add_index_setting connection
      index_key = connection.index_key model_class, :id
      @setting  = connection.fetch index_key
    end

    describe "attributes" do
      subject { @setting }

      its([:id])     { should be_kind_of Fixnum }
      its([:index])  { should eql "PRIMARY" }
      its([:fields]) { should eql %W[id name age status] }
      its([:opened]) { should be }
    end

    context "when key but not a index_key given" do
      it "should raise error" do
        expect {
          connection.fetch :id
        }.to raise_error ActiveRecordHandlerSocket::UnknownIndexError
      end
    end

    context "when unknown key given" do
      it "should raise error" do
        expect {
          connection.fetch :unknown
        }.to raise_error ActiveRecordHandlerSocket::UnknownIndexError
      end
    end
  end
end

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
      subject                 { connection }
      it                      { should be_kind_of klass }
      its(:logger)            { should eql ActiveRecord::Base.logger }
      its(:model_class)       { should eql ActiveRecord::Base }
      its(:indexes)           { should be_blank }
      its(:indexes)           { should be_kind_of Hash }
      its(:index_count_cache) { should eql 0 }

      describe ".connections" do
        subject       { connection.connections }
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
        it      { should eql model_class }
      end
    end
  end

  describe "#initialize" do
    context "without options" do
      before :each do
        @connection = klass.new logger
      end

      subject                 { @connection }
      it                      { should be_kind_of klass }
      its(:logger)            { should eql ActiveRecord::Base.logger }
      its(:model_class)       { should eql ActiveRecord::Base }
      its(:indexes)           { should be_blank }
      its(:indexes)           { should be_kind_of Hash }
      its(:index_count_cache) { should eql 0 }

      describe ".connections" do
        subject       { @connection.connections }
        its([:read])  { should be_nil }
        its([:write]) { should be_nil }
      end
    end

    context "with model_class option" do
      before :each do
        @connection = klass.new logger, :model_class => model_class
      end

      subject           { @connection }
      its(:model_class) { should eql model_class }
    end
  end

  describe "#establish_connection" do
    before :each do
      @connection = klass.new logger
    end

    context "before establish for read" do
      subject { @connection.connections[:read] }
      it      { should be_nil }
    end

    context "before establish for write" do
      subject { @connection.connections[:write] }
      it      { should be_nil }
    end

    context "with read" do
      before :each do
        connection.establish_connection :read
      end

      subject { connection.read_connection }
      it { should be_kind_of HandlerSocket }

      describe ":@current_config" do
        let(:config) {
          _config = connection.connection_config :read
          _config.slice :host, :port
        }
        subject      { connection.read_connection.instance_variable_get :@_current_config }
        its([:host]) { should eql config[:host] }
        its([:port]) { should eql config[:port] }
      end
    end

    context "with write" do
      before :each do
        connection.establish_connection :write
      end

      subject { connection.write_connection }
      it      { should be_kind_of HandlerSocket }

      describe ":@current_config" do
        let(:config) {
          _config = connection.connection_config :write
          _config.slice :host, :port
        }
        subject      { connection.write_connection.instance_variable_get(:@_current_config) }
        its([:host]) { should eql config[:host] }
        its([:port]) { should eql config[:port] }
      end
    end

    context "with unknown" do
      subject { lambda { connection.establish_connection :unknown } }
      it { should raise_error ArgumentError }
    end
  end

  describe "#read_connection" do
    subject { connection.read_connection }
    it      { should be_kind_of HandlerSocket }
  end

  describe "#write_connection" do
    subject { connection.write_connection }
    it      { should be_kind_of HandlerSocket }
  end

  describe "#reconnect!" do
    before :each do
      add_index_setting connection

      connection.read_connection.close
      connection.write_connection.close

      connection.reset_opened_indexes
    end

    subject { connection.reconnect! }
    it      { should be true }

    context "then find" do
      before :each do
        FactoryGirl.create :bob
        connection.reconnect!
        stub_object model_class, :hs_connection,  connection
      end

      subject     { model_class.hsfind_by_id 1 }
      its(:class) { should eql model_class }
      its(:id)    { should eql 1 }
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

      its(:class)  { should eql model_class }
      its(:name)   { should eql "Test" }
      its(:age)    { should eql 24 }
      its(:status) { should be true }
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
      it { should be false }
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
      it { should be false }
    end
  end

  describe "#acitve?" do
    before :each do
      add_index_setting connection
    end

    context "when connected" do
      subject { connection.active? }
      it      { should be true }
    end

    context "when read closed" do
      before :each do
        connection.read_connection.close
      end

      after :each do
        connection.reconnect!
      end

      subject { connection.active? }
      it      { should be false }
    end

    context "when write closed" do
      before :each do
        connection.write_connection.close
      end

      after :each do
        connection.reconnect!
      end

      subject { connection.active? }
      it      { should be false }
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
        it { should be true }
      end

      describe "before opened" do
        subject {
          index_key = connection.index_key model_class, :id
          setting = connection.fetch index_key
          setting[:opened]
        }
        it { should be false }
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
        it { should be true }
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
        it { should be true }
      end

      describe "before opened" do
        subject {
          index_key = connection.index_writer_key model_class
          setting = connection.fetch index_key
          setting[:opened]
        }
        it { should be false }
      end

      describe "marked index setting opened" do
        subject {
          index_key = connection.index_writer_key model_class
          connection.open_index model_class, index_key, :write
          setting = connection.fetch index_key
          setting[:opened]
        }
        it { should be true }
      end
    end

    context "when invalid result" do
      before :each do
        stub_object connection.read_connection, :open_index, 2
        stub_object connection.read_connection, :error,      "err"

        connection.reconnect!
      end

      subject {
        lambda {
          index_key = connection.index_key model_class, :id
          connection.open_index model_class, index_key
        }
      }
      it { should raise_error ArgumentError }

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
        it { should be false }
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
        it { should be true }
      end
    end

    context "when connection error" do
      before :each do
        stub_object connection.read_connection, :open_index, -1
        stub_object connection.read_connection, :error,      "connection lost"

        connection.reconnect!
      end

      subject {
        lambda {
          index_key = connection.index_key model_class, :id
          connection.open_index model_class, index_key
        }
      }
      it { should raise_error ActiveRecordHandlerSocket::CannotConnectError }

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
        it { should be false }
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
        it { should be false }
      end
    end
  end

  describe "#connection_config" do
    context :read do
      let(:base_config) { ActiveRecord::Base.configurations["#{RAILS_ENV}_hs_read"].symbolize_keys }
      subject           { connection.connection_config :read }
      its([:host])      { should eql base_config[:host] }
      its([:port])      { should eql base_config[:port] }
      its([:database])  { should eql base_config[:database] }
    end

    context :write do
      let(:base_config) { ActiveRecord::Base.configurations["#{RAILS_ENV}_hs_write"].symbolize_keys }
      subject           { connection.connection_config :write }
      its([:host])      { should eql base_config[:host] }
      its([:port])      { should eql base_config[:port] }
      its([:database])  { should eql base_config[:database] }
    end
  end

  describe "#index_count" do
    let(:initial_count) { connection.index_count_cache }
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
        it { should be true }
      end

      describe "for Hobby:id" do
        subject {
          index_key = connection.index_key another_model_class, :id
          connection.indexes[index_key][:opened]
        }
        it { should be true }
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
        it { should be false }
      end

      describe "for Hobby:id" do
        subject {
          index_key = connection.index_key another_model_class, :id
          connection.indexes[index_key][:opened]
        }
        it { should be false }
      end
    end
  end

  describe "#add_index_setting" do
    let(:index_name) { "index_people_on_age_and_status" }
    let(:key)        { :age_and_status }
    let(:index_key)  { connection.index_key model_class, key }
    subject          { connection.add_index_setting model_class, key, index_name }
    it               { should eql index_key }

    context "with columns" do
      before :each do
        @initial_count = connection.index_count_cache
        connection.add_index_setting model_class, key, index_name, :columns => %W[id name age]
      end

      let(:setting) {
        {
          :id     => @initial_count + 1,
          :index  => index_name,
          :fields => %W[id name age],
          :opened => false
        }
      }
      subject        { connection.fetch index_key }
      its([:id])     { should eql setting[:id] }
      its([:index])  { should eql setting[:index] }
      its([:fields]) { should eql setting[:fields] }
      its([:opened]) { should eql setting[:opened] }

      context "with write option" do
        before :each do
          @initial_count = connection.index_count_cache
          connection.add_index_setting model_class, key, index_name, :columns => %W[id name age], :write => true
        end

        let(:setting) {
          {
            :id     => @initial_count + 1,
            :index  => index_name,
            :fields => %W[name age],
            :opened => false
          }
        }
        subject        { connection.fetch index_key }
        its([:id])     { should eql setting[:id] }
        its([:index])  { should eql setting[:index] }
        its([:fields]) { should eql setting[:fields] }
        its([:opened]) { should eql setting[:opened] }
      end

      context "with empty columns" do
        before :each do
          @initial_count = connection.index_count_cache
        end

        subject { lambda { connection.add_index_setting model_class, key, index_name, :columns => [] } }
        it      { should raise_error ArgumentError }
      end

      context "with writer specified columns only id" do
        before :each do
          @initial_count = connection.index_count_cache
        end

        subject { lambda { connection.add_index_setting model_class, key, index_name, :columns => [:id], :write => true } }
        it      { should raise_error ArgumentError }
      end
    end

    context "without columns" do
      before :each do
        @initial_count = connection.index_count_cache
        connection.add_index_setting model_class, key, index_name
      end

      let(:setting) {
        {
          :id     => @initial_count + 1,
          :index  => index_name,
          :fields => %W[id name age status],
          :opened => false
        }
      }
      subject        { connection.fetch index_key }
      its([:id])     { should eql setting[:id] }
      its([:index])  { should eql setting[:index] }
      its([:fields]) { should eql setting[:fields] }
      its([:opened]) { should eql setting[:opened] }

      context "with write option" do
        before :each do
          @initial_count = connection.index_count_cache
          connection.add_index_setting model_class, key, index_name, :write => true
        end

        let(:setting) {
          {
            :id     => @initial_count + 1,
            :index  => index_name,
            :fields => %W[name age status],
            :opened => false
          }
        }
        subject        { connection.fetch index_key }
        its([:id])     { should eql setting[:id] }
        its([:index])  { should eql setting[:index] }
        its([:fields]) { should eql setting[:fields] }
        its([:opened]) { should eql setting[:opened] }
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
      it { should match /ActiveRecordHandlerSocket: #{index_key} was updated/ }
    end

    context "when multi-time call" do
      before :each do
        @first_index_key  = connection.add_index_setting model_class, :first,  index_name
        @second_index_key = connection.add_index_setting model_class, :second, index_name
      end

      let(:first_setting) {
        first_setting = connection.fetch @first_index_key
        first_setting
      }
      subject    { connection.fetch @second_index_key }
      its([:id]) { should eql first_setting[:id] + 1  }
    end
  end

  describe "#index_key" do
    subject { connection.index_key model_class, :id }
    it      { should eql [ model_class, :id ].join(":") }
  end

  describe "#index_writer_key" do
    subject { connection.index_writer_key model_class }
    it      { should eql [ model_class, klass::WRITER_KEY ].join(":") }
  end

  describe "#fetch" do
    before :each do
      add_index_setting connection
      index_key = connection.index_key model_class, :id
      @setting  = connection.fetch index_key
    end

    describe "attributes" do
      subject        { @setting }
      its([:id])     { should be_kind_of Fixnum }
      its([:index])  { should eql "PRIMARY" }
      its([:fields]) { should eql %W[id name age status] }
      its([:opened]) { should be }
    end

    context "when key but not a index_key given" do
      subject { lambda { connection.fetch :id } }
      it      { should raise_error ActiveRecordHandlerSocket::UnknownIndexError }
    end

    context "when unknown key given" do
      subject { lambda { connection.fetch :unknown } }
      it      { should raise_error ActiveRecordHandlerSocket::UnknownIndexError }
    end
  end
end

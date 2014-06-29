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
      describe "returned value" do
        subject do
          connection
        end

        it "should return connection instance" do
          expect(subject).to be_kind_of(klass)
        end
      end

      describe ".logger" do
        subject do
          connection.logger
        end

        it "should same given logger" do
          expect(subject).to eql(ActiveRecord::Base.logger)
        end
      end

      describe ".model_class" do
        subject do
          connection.model_class
        end

        it "should same given logger" do
          expect(subject).to eql(ActiveRecord::Base)
        end
      end

      describe ".connections" do
        subject do
          connection.connections
        end

        context :read do
          subject do
            connection.connections[:read]
          end

          it "should set read connection" do
            expect(subject).to be_kind_of(HandlerSocket)
          end
        end

        context :write do
          subject do
            connection.connections[:write]
          end

          it "should set write connection" do
            expect(subject).to be_kind_of(HandlerSocket)
          end
        end
      end

      describe ".indexes" do
        subject do
          connection.indexes
        end

        it "should set blank hash" do
          expect(subject).to be_blank
          expect(subject).to be_kind_of(Hash)
        end
      end

      describe ".index_count_cache" do
        subject do
          connection.index_count_cache
        end

        it "should set 0" do
          expect(subject).to eql(0)
        end
      end
    end

    context "with model_class option" do
      before :each do
        @connection = klass.establish_connection logger, :model_class => model_class
      end

      describe ".model_class" do
        subject do
          @connection.model_class
        end

        it "should same given logger" do
          expect(subject).to eql(model_class)
        end
      end
    end
  end

  describe "#initialize" do
    context "without options" do
      before :each do
        @connection = klass.new logger
      end

      describe "returned value" do
        subject do
          @connection
        end

        it "should return connection instance" do
          expect(subject).to be_kind_of(klass)
        end
      end

      describe ".logger" do
        subject do
          @connection.logger
        end

        it "should same given logger" do
          expect(subject).to eql(ActiveRecord::Base.logger)
        end
      end

      describe ".model_class" do
        subject do
          @connection.model_class
        end

        it "should same given logger" do
          expect(subject).to eql(ActiveRecord::Base)
        end
      end

      describe ".connections" do
        subject do
          @connection.connections
        end

        context :read do
          subject do
            @connection.connections[:read]
          end

          it "should set read connection" do
            expect(subject).to be_nil
          end
        end

        context :write do
          subject do
            @connection.connections[:write]
          end

          it "should set write connection" do
            expect(subject).to be_nil
          end
        end
      end

      describe ".indexes" do
        subject do
          @connection.indexes
        end

        it "should set blank hash" do
          expect(subject).to be_blank
          expect(subject).to be_kind_of(Hash)
        end
      end

      describe ".index_count_cache" do
        subject do
          @connection.index_count_cache
        end

        it "should set 0" do
          expect(subject).to eql(0)
        end
      end
    end

    context "with model_class option" do
      before :each do
        @connection = klass.new logger, :model_class => model_class
      end

      describe ".model_class" do
        subject do
          @connection.model_class
        end

        it "should same given logger" do
          expect(subject).to eql(model_class)
        end
      end
    end
  end

  describe "#establish_connection" do
    before :each do
      @connection = klass.new logger
    end

    context "before establish for read" do
      subject do
        @connection.connections[:read]
      end

      it "should not have connections" do
        expect(subject).to be_nil
      end
    end

    context "before establish for write" do
      subject do
        @connection.connections[:write]
      end

      it "should not have connections" do
        expect(subject).to be_nil
      end
    end

    context "with read" do
      before :each do
        connection.establish_connection :read
      end

      subject do
        connection.read_connection
      end

      it "should have instance" do
        expect(subject).to be_kind_of(HandlerSocket)
      end

      describe ":@current_config" do
        subject do
          connection.read_connection.instance_variable_get(:@_current_config)
        end

        it "should have current_config" do
          config = connection.connection_config :read
          config = config.slice :host, :port

          expect(subject).to eql(config)
        end
      end
    end

    context "with write" do
      before :each do
        connection.establish_connection :write
      end

      describe "object" do
        subject do
          connection.write_connection
        end

        it "should have instance" do
          expect(subject).to be_kind_of(HandlerSocket)
        end
      end

      describe ":@current_config" do
        subject do
          connection.write_connection.instance_variable_get(:@_current_config)
        end

        it "should have current_config" do
          config = connection.connection_config :write
          config = config.slice :host, :port

          expect(subject).to eql(config)
        end
      end
    end

    context "with unknown" do
      it do
        expect{
          connection.establish_connection :unknown
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#read_connection" do
    subject do
      connection.read_connection
    end

    it "should return handlersocket" do
      expect(subject).to be_kind_of(HandlerSocket)
    end
  end

  describe "#write_connection" do
    subject do
      connection.write_connection
    end

    it "should return handlersocket" do
      expect(subject).to be_kind_of(HandlerSocket)
    end
  end

  describe "#reconnect!" do
    before :each do
      add_index_setting connection

      connection.read_connection.close
      connection.write_connection.close

      connection.reset_opened_indexes
    end

    subject do
      connection.reconnect!
    end

    it "should return true" do
      expect(subject).to be
    end

    context "then find" do
      before :each do
        FactoryGirl.create(:bob)
        connection.reconnect!
        stub_object model_class, :hs_connection,  connection
      end

      subject do
        model_class.hsfind_by_id 1
      end

      it "should found" do
        expect(subject).to be_kind_of(model_class)
      end
    end

    context "then create" do
      before :each do
        connection.reconnect!
        stub_object model_class, :hs_connection, connection
      end

      subject do
        id = model_class.hscreate :name => "Test", :age => 24, :status => true
        model_class.hsfind_by_id id
      end

      it "should created" do
        expect(subject).to be_kind_of(model_class)
      end
    end

    context "then index_setting for read" do
      before :each do
        connection.reconnect!
      end

      subject do
        index_key = connection.index_key model_class, :id
        setting   = connection.fetch index_key
        setting[:opened]
      end

      it "should setting reset" do
        expect(subject).not_to be
      end
    end

    context "then index_setting for write" do
      before :each do
        connection.reconnect!
      end

      subject do
        index_key = connection.index_writer_key model_class
        setting   = connection.fetch index_key
        setting[:opened]
      end

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
      subject do
        connection.active?
      end

      it "should return true" do
        expect(subject).to be
      end
    end

    context "when read closed" do
      subject do
        connection.active?
      end

      before :each do
        connection.read_connection.close
      end

      it "should return false" do
        expect(subject).not_to be
      end
    end

    context "when write closed" do
      subject do
        connection.active?
      end

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
      subject do
        index_key = connection.index_key model_class, :id
        connection.open_index model_class, index_key
      end

      it "should just return" do
        expect(subject).to be_nil
      end
    end

    context "when open index" do
      before :each do
        connection.reconnect!
      end

      describe "return value" do
        subject do
          index_key = connection.index_key model_class, :id
          connection.open_index model_class, index_key
        end

        it do
          expect(subject).to be
        end
      end

      describe "before opened" do
        subject do
          index_key = connection.index_key model_class, :id
          setting = connection.fetch index_key
          setting[:opened]
        end

        it do
          expect(subject).not_to be
        end
      end

      describe "marked index setting opened" do
        before :each do
          index_key = connection.index_key model_class, :id
          connection.open_index model_class, index_key
        end

        subject do
          index_key = connection.index_key model_class, :id
          setting = connection.fetch index_key
          setting[:opened]
        end

        it do
          expect(subject).to be
        end
      end
    end

    context "when open write index" do
      before :each do
        connection.reconnect!
      end

      describe "return value" do
        subject do
          index_key = connection.index_writer_key model_class
          connection.open_index model_class, index_key, :write
        end

        it do
          expect(subject).to be
        end
      end

      describe "before opened" do
        subject do
          index_key = connection.index_writer_key model_class
          setting = connection.fetch index_key
          setting[:opened]
        end

        it do
          expect(subject).not_to be
        end
      end

      describe "marked index setting opened" do
        subject do
          index_key = connection.index_writer_key model_class
          connection.open_index model_class, index_key, :write
          setting = connection.fetch index_key
          setting[:opened]
        end

        it do
          expect(subject).to be
        end
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
        }.to raise_error(ArgumentError)
      end

      describe "index setting for Person:id" do
        before :each do
          begin
            index_key = connection.index_key model_class, :id
            connection.open_index model_class, index_key
          rescue ArgumentError
          end
        end

        subject do
          index_key = connection.index_key model_class, :id
          setting = connection.fetch index_key
          setting[:opened]
        end

        it do
          expect(subject).not_to be
        end
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

        subject do
          index_key = connection.index_key another_model_class, :id
          setting = connection.fetch index_key
          setting[:opened]
        end

        it do
          expect(subject).to be
        end
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
        }.to raise_error(ActiveRecordHandlerSocket::CannotConnectError)
      end

      describe "index setting for Person:id" do
        before :each do
          begin
            index_key = connection.index_key model_class, :id
            connection.open_index model_class, index_key
          rescue ActiveRecordHandlerSocket::CannotConnectError
          end
        end

        subject do
          index_key = connection.index_key model_class, :id
          setting = connection.fetch index_key
          setting[:opened]
        end

        it do
          expect(subject).not_to be
        end
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

        subject do
          index_key = connection.index_key another_model_class, :id
          setting = connection.fetch index_key
          setting[:opened]
        end

        it do
          expect(subject).not_to be
        end
      end
    end
  end

  describe "#connection_config" do
    context :read do
      subject do
        connection.connection_config :read
      end

      it do
        expect(subject).to eql(ActiveRecord::Base.configurations["#{RAILS_ENV}_hs_read"].symbolize_keys)
      end
    end

    context :write do
      subject do
        connection.connection_config :write
      end

      it do
        expect(subject).to eql(ActiveRecord::Base.configurations["#{RAILS_ENV}_hs_write"].symbolize_keys)
      end
    end
  end

  describe "#index_count" do
    let :initial_count do
      connection.index_count_cache
    end

    it "should increment" do
      # initialize
      initial_count

      expect(connection.index_count).to eql(initial_count + 1)
      expect(connection.index_count).to eql(initial_count + 2)
      expect(connection.index_count).to eql(initial_count + 3)
    end
  end

  describe "#reset_opened_indexes" do
    before :each do
      add_index_setting connection
    end

    context "before reset" do
      describe "for Person:id" do
        subject do
          index_key = connection.index_key model_class, :id
          connection.indexes[index_key][:opened]
        end

        it do
          expect(subject).to be
        end
      end

      describe "for Hobby:id" do
        subject do
          index_key = connection.index_key another_model_class, :id
          connection.indexes[index_key][:opened]
        end

        it do
          expect(subject).to be
        end
      end
    end

    context "after reset" do
      before :each do
        connection.reset_opened_indexes
      end

      describe "for Person:id" do
        subject do
          index_key = connection.index_key model_class, :id
          connection.indexes[index_key][:opened]
        end

        it do
          expect(subject).not_to be
        end
      end

      describe "for Hobby:id" do
        subject do
          index_key = connection.index_key another_model_class, :id
          connection.indexes[index_key][:opened]
        end

        it do
          expect(subject).not_to be
        end
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

    subject do
      connection.add_index_setting model_class, key, index_name
    end

    it "returns index_key" do
      expect(subject).to eql(index_key)
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

      subject do
        connection.fetch index_key
      end

      it do
        expect(subject).to eql(setting)
      end

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

        subject do
          connection.fetch index_key
        end

        it do
          expect(subject).to eql(setting)
        end
      end

      context "with empty columns" do
        before :each do
          @initial_count = connection.index_count_cache
        end

        it do
          expect{
            connection.add_index_setting model_class, key, index_name, :columns => []
          }.to raise_error(ArgumentError)
        end
      end

      context "with writer specified columns only id" do
        before :each do
          @initial_count = connection.index_count_cache
        end

        it do
          expect{
            connection.add_index_setting model_class, key, index_name, :columns => [:id], :write => true
          }.to raise_error(ArgumentError)
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

      subject do
        connection.fetch index_key
      end

      it do
        expect(subject).to eql(setting)
      end

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

        subject do
          connection.fetch index_key
        end

        it do
          expect(subject).to eql(setting)
        end
      end
    end

    context "when existing setting overwrite" do
      before :each do
        connection.add_index_setting model_class, key, index_name
        connection.add_index_setting model_class, key, index_name
      end

      subject do
        warning_log.rewind
        warned = warning_log.read.chomp
      end

      it do
        expect(subject).to match(/ActiveRecordHandlerSocket: #{index_key} was updated/)
      end
    end

    context "when multi-time call" do
      before :each do
        @first_index_key  = connection.add_index_setting model_class, :first,  index_name
        @second_index_key = connection.add_index_setting model_class, :second, index_name
      end

      subject do
        first_setting = connection.fetch @first_index_key
        first_setting[:id]
      end

      it "should increment" do
        second_setting = connection.fetch @second_index_key
        expect(subject).to eql(second_setting[:id] - 1)
      end
    end
  end

  describe "#index_key" do
    subject do
      connection.index_key model_class, :id
    end

    it do
      expect(subject).to eql([ model_class, :id ].join(":"))
    end
  end

  describe "#index_writer_key" do
    subject do
      connection.index_writer_key model_class
    end

    it do
      expect(subject).to eql([ model_class, klass::WRITER_KEY ].join(":"))
    end
  end

  describe "#fetch" do
    before :each do
      add_index_setting connection
      index_key = connection.index_key model_class, :id
      @setting  = connection.fetch index_key
    end

    context "with id" do
      subject do
        @setting[:id]
      end

      it do
        expect(subject).to be_kind_of(Fixnum)
      end
    end

    context "with index" do
      subject do
        @setting[:index]
      end

      it do
        expect(subject).to eql("PRIMARY")
      end
    end

    context "with fields" do
      subject do
        @setting[:fields]
      end

      it do
        expect(subject).to eql(%W[id name age status])
      end
    end

    context "with opened" do
      subject do
        @setting[:opened]
      end

      it do
        expect(subject).to be
      end
    end

    context "when key but not a index_key given" do
      it "should raise error" do
        expect{
          connection.fetch :id
        }.to raise_error(ActiveRecordHandlerSocket::UnknownIndexError)
      end
    end

    context "when unknown key given" do
      it "should raise error" do
        expect{
          connection.fetch :unknown
        }.to raise_error(ActiveRecordHandlerSocket::UnknownIndexError)
      end
    end
  end
end

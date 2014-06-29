require 'spec_helper'

describe ActiveRecordHandlerSocket::Connection do
  let :klass do
    ActiveRecordHandlerSocket::Connection
  end

  let :model_class do
    Person
  end

  let :logger do
    ActiveRecord::Base.logger
  end

  let! :connection do
    instance = klass.new ActiveRecord::Base.logger
    instance.establish_connection :read
    instance.establish_connection :write
    instance
  end

  def add_index_setting
    index_key   = @connection.index_key model_class, :id
    @connection.add_index_setting model_class, index_key, "PRIMARY"
    @connection.open_index model_class, index_key

    index_key   = @connection.index_writer_key model_class
    @connection.add_index_setting model_class, index_key, "PRIMARY"
    @connection.open_index model_class, index_key
  end

  describe ".establish_connection" do
    context "without options" do
      before :each do
        @connection = klass.establish_connection logger
      end

      describe "returned value" do
        subject do
          @connection
        end

        it "should return connection instance" do
          be_kind_of klass
        end
      end

      describe ".logger" do
        subject do
          @conneciton.logger
        end

        it "should same given logger" do
          eql ActiveRecord::Base.logger
        end
      end

      describe ".model_class" do
        subject do
          @conneciton.model_class
        end

        it "should same given logger" do
          eql ActiveRecord::Base
        end
      end

      describe ".connections" do
        subject do
          @connection.connections
        end

        it "should set read conneciton" do
          expect(subject[:read]).to be
          expect(subject[:read]).to be_kind_of(HandlerSocket)
        end

        it "should set write conneciton" do
          expect(subject[:write]).to be
          expect(subject[:write]).to be_kind_of(HandlerSocket)
        end
      end

      describe ".indexes" do
        subject do
          @connection.indexes
        end

        it "should set blank hash" do
          be_blank
          be_kind_of Hash
        end
      end

      describe ".index_count_cache" do
        subject do
          @connection.index_count_cache
        end

        it "should set 0" do
          eql 0
        end
      end
    end

    context "with model_class option" do
      before :each do
        @connection = klass.establish_connection logger, :model_class => model_class
      end

      describe ".model_class" do
        subject do
          @conneciton.model_class
        end

        it "should same given logger" do
          eql model_class
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
          be_kind_of klass
        end
      end

      describe ".logger" do
        subject do
          @conneciton.logger
        end

        it "should same given logger" do
          eql ActiveRecord::Base.logger
        end
      end

      describe ".model_class" do
        subject do
          @conneciton.model_class
        end

        it "should same given logger" do
          eql ActiveRecord::Base
        end
      end

      describe ".connections" do
        subject do
          @connection.connections
        end

        it "should set read conneciton" do
          expect(subject[:read]).to be_nil
        end

        it "should set write conneciton" do
          expect(subject[:write]).to be_nil
        end
      end

      describe ".indexes" do
        subject do
          @connection.indexes
        end

        it "should set blank hash" do
          be_blank
          be_kind_of Hash
        end
      end

      describe ".index_count_cache" do
        subject do
          @connection.index_count_cache
        end

        it "should set 0" do
          eql 0
        end
      end
    end

    context "with model_class option" do
      before :each do
        @connection = klass.new logger, :model_class => model_class
      end

      describe ".model_class" do
        subject do
          @conneciton.model_class
        end

        it "should same given logger" do
          eql model_class
        end
      end
    end
  end

  describe "#read_connection" do
    subject do
      @connection = klass.establish_connection logger
      @connection.read_connection
    end

    it "should return handlersocket" do
      be_kind_of HandlerSocket
    end
  end

  describe "#write_connection" do
    subject do
      @connection = klass.establish_connection logger
      @connection.write_connection
    end

    it "should return handlersocket" do
      be_kind_of HandlerSocket
    end
  end

  describe "#reconnect!" do
    before :each do
      @connection = klass.establish_connection logger
      add_index_setting

      @connection.read_connection.close
      @connection.write_connection.close

      @connection.reset_opened_indexes
    end

    subject do
      @connection.reconnect!
    end

    it "should return true" do
      be
    end

    context "then find" do
      before :each do
        @connection.reconnect!
      end

      subject do
        model_class.hsfind_by_id 1
      end

      it "should found" do
        be_kind_of model_class
      end
    end

    context "then create" do
      before :each do
        @connection.reconnect!
      end

      subject do
        id = model_class.hscreate :name => "Test", :age => 24, :status => true
        model_class.hsfind_by_id id
      end

      it "should created" do
        be_kind_of model_class
      end
    end

    context "then index_setting for read" do
      before :each do
        @connection.reconnect!
      end

      subject do
        index_key = @connection.index_key model_class, :id
        setting = @connection.fetch index_key
        setting[:opened]
      end

      it "should setting reset" do
        be_falsy
      end
    end

    context "then index_setting for write" do
      before :each do
        @connection.reconnect!
      end

      subject do
        index_key = @connection.index_writer_key model_class
        setting = @connection.fetch index_key
        setting[:opened]
      end

      it "should setting reset" do
        be_falsy
      end
    end
  end

  describe "#acitve?" do
    before :each do
      @connection = klass.establish_connection logger
      add_index_setting
    end

    context "when connected" do
      subject do
        @connection.active?
      end

      it "should return true" do
        be
      end
    end

    context "when read closed" do
      subject do
        @connection.active?
      end

      before :each do
        @connection.read_connection.close
      end

      it "should return false" do
        be_falsy
      end
    end

    context "when write closed" do
      subject do
        @connection.active?
      end

      before :each do
        # open index
        @connection.write_connection.close
      end

      it "should return false" do
        be_falsy
      end
    end
  end


  describe "#open_index" do
  end

  describe "#connection_config" do
  end

  describe "#index_count" do
  end

  describe "#reset_opened_index" do
  end

  describe "#add_index_setting" do
  end

  describe "#index_key" do
    before :each do
      @connection = klass.establish_connection logger
    end

    subject do
      @connection.index_key model_class, :id
    end

    it do
      [ model_class, :id ].join ":"
    end
  end

  describe "#index_writer_key" do
    before :each do
      @connection = klass.establish_connection logger
    end

    subject do
      @connection.index_writer_key model_class
    end

    it do
      [ model_class, klass::WRITER_KEY ].join ":"
    end
  end

  describe "#fetch" do
    before :each do
      @connection = klass.establish_connection logger
      add_index_setting
      index_key = @connection.index_key model_class, :id
      @setting = @connection.fetch index_key
    end

    context "with id" do
      subject do
        @setting[:id]
      end

      it do
        be_kind_of Fixnum
      end
    end

    context "with index" do
      subject do
        @setting[:index]
      end

      it do
        eql "PRIMARY"
      end
    end

    context "with fields" do
      subject do
        @setting[:fields]
      end

      it do
        eql %W[id name age status]
      end
    end

    context "with opened" do
      subject do
        @setting[:opened]
      end

      it do
        be
      end
    end

    context "when key but not a index_key given" do
      subject do
        @connection.fetch :id
      end

      it "should raise error" do
        raise_error ActiveRecordHandlerSocket::UnknownIndexError
      end
    end

    context "when unknown key given" do
      subject do
        @connection.fetch :unknown
      end

      it "should raise error" do
        raise_error ActiveRecordHandlerSocket::UnknownIndexError
      end
    end
  end



  # describe "hs_index_count" do
  #   it "should be private method" do
  #     expect{
  #       klass.hs_index_count
  #     }.to raise_error(NoMethodError)
  #   end

  #   it "should increment hs_index_count_cache" do
  #     initial_count = klass.__send__(:hs_index_count_cache)
  #     klass.__send__(:hs_index_count)
  #     expect(klass.__send__(:hs_index_count_cache)).to eql(initial_count + 1)
  #     klass.__send__(:hs_index_count)
  #     expect(klass.__send__(:hs_index_count_cache)).to eql(initial_count + 2)
  #   end
  # end

  # describe "hs_reset_opened_index" do
  #   it "should mark not opened for all index settings" do
  #     klass.hsfind_by_id(1)
  #     another_klass.hsfind_by_id(1)

  #     expect(ActiveRecord::Base.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).to be
  #     expect(ActiveRecord::Base.__send__(:hs_indexes)[another_klass.__send__(:hs_index_key, "id")][:opened]).to be

  #     klass.__send__(:hs_reset_opened_indexes)

  #     expect(ActiveRecord::Base.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).not_to be
  #     expect(ActiveRecord::Base.__send__(:hs_indexes)[another_klass.__send__(:hs_index_key, "id")][:opened]).not_to be
  #   end
  # end



  # describe "hs_establish_connection" do
  #   context "when no name given" do
  #     before :each do
  #       @original_connections = ActiveRecord::Base.__send__ :hs_connections
  #       ActiveRecordHandlerSocket::Connection::PrivateMethods.__send__ :class_variable_set, :@@hs_connections, {}
  #     end

  #     after :each do
  #       ActiveRecordHandlerSocket::Connection::PrivateMethods.__send__ :class_variable_set, :@@hs_connections, @original_connections
  #     end

  #     it "should add read connection" do
  #       ActiveRecord::Base.__send__ :hs_establish_connection
  #       expect(ActiveRecord::Base.__send__(:hs_connections)[:read]).to be_kind_of(HandlerSocket)
  #     end

  #     it "should add write connection" do
  #       ActiveRecord::Base.__send__ :hs_establish_connection
  #       expect(ActiveRecord::Base.__send__(:hs_connections)[:write]).to be_kind_of(HandlerSocket)
  #     end
  #   end

  #   context "when read connection" do
  #     before :each do
  #       @original_connections = ActiveRecord::Base.__send__ :hs_connections
  #       ActiveRecordHandlerSocket::Connection::PrivateMethods.__send__ :class_variable_set, :@@hs_connections, {}
  #     end

  #     after :each do
  #       ActiveRecordHandlerSocket::Connection::PrivateMethods.__send__ :class_variable_set, :@@hs_connections, @original_connections
  #     end

  #     it "should add read connection" do
  #       ActiveRecord::Base.__send__ :hs_establish_connection, :read
  #       expect(ActiveRecord::Base.__send__(:hs_connections)[:read]).to be_kind_of(HandlerSocket)
  #     end

  #     it "should add write connection" do
  #       ActiveRecord::Base.__send__ :hs_establish_connection, :write
  #       expect(ActiveRecord::Base.__send__(:hs_connections)[:write]).to be_kind_of(HandlerSocket)
  #     end
  #   end

  #   context "when unknown configuration name given" do
  #     it "should raise error" do
  #       expect{
  #         ActiveRecord::Base.__send__ :hs_establish_connection, "test_hs_read"
  #       }.to raise_error(ArgumentError)
  #     end
  #   end
  # end

  # describe "hs_open_index" do
  #   context "when index opened" do
  #     before :each do
  #       klass.hsfind_by_id 1
  #     end

  #     it "should just return" do
  #       expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).to be

  #       expect(klass.__send__(:hs_open_index, klass.__send__(:hs_index_key, "id"))).to be_nil
  #     end
  #   end

  #   context "when open index" do
  #     before :each do
  #       ActiveRecord::Base.__send__ :hs_reconnect!
  #     end

  #     it "should return true and mark opened" do
  #       expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).not_to be

  #       expect(klass.__send__(:hs_open_index, klass.__send__(:hs_index_key, "id"))).to be

  #       expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).to be
  #     end
  #   end

  #   context "when open write index" do
  #     before :each do
  #       ActiveRecord::Base.__send__ :hs_reconnect!
  #     end

  #     it "should return true and mark opened" do
  #       expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_writer_key)][:opened]).not_to be

  #       expect(klass.__send__(:hs_open_index, klass.__send__(:hs_index_writer_key))).to be

  #       expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_writer_key)][:opened]).to be
  #     end
  #   end

  #   context "when invalid result" do
  #     before :each do
  #       ActiveRecord::Base.__send__ :hs_reconnect!
  #       Hobby.hsfind_by_id 1

  #       stub_object ActiveRecord::Base.__send__(:hs_read_connection), :open_index, 2
  #       stub_object ActiveRecord::Base.__send__(:hs_read_connection), :error, "err"
  #     end

  #     it "should raise error" do
  #       expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).not_to be
  #       expect(another_klass.__send__(:hs_indexes)[another_klass.__send__(:hs_index_key, "id")][:opened]).to be

  #       expect{
  #         klass.__send__ :hs_open_index, klass.__send__(:hs_index_key, "id")
  #       }.to raise_error(ArgumentError)

  #       expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).not_to be
  #       expect(another_klass.__send__(:hs_indexes)[another_klass.__send__(:hs_index_key, "id")][:opened]).to be
  #     end
  #   end

  #   context "when connection error" do
  #     before :each do
  #       ActiveRecord::Base.__send__ :hs_reconnect!
  #       another_klass.hsfind_by_id 1

  #       stub_object(ActiveRecord::Base.__send__(:hs_read_connection), :open_index, -1)
  #       stub_object(ActiveRecord::Base.__send__(:hs_read_connection), :error, "connection lost")
  #     end

  #     it "should raise error" do
  #       expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).not_to be
  #       expect(another_klass.__send__(:hs_indexes)[another_klass.__send__(:hs_index_key, "id")][:opened]).to be

  #       expect{
  #         klass.__send__ :hs_open_index, klass.__send__(:hs_index_key, "id")
  #       }.to raise_error(ActiveRecordHandlerSocket::CannotConnectError)

  #       expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).not_to be
  #       expect(another_klass.__send__(:hs_indexes)[another_klass.__send__(:hs_index_key, "id")][:opened]).not_to be
  #     end
  #   end
  # end
end

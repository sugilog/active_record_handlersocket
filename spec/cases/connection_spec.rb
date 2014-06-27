require 'spec_helper'

describe "ConnectionSpec" do
  let :klass do
    Person
  end

  let :another_klass do
    Hobby
  end

  describe "hs_reconnect!" do
    before :each do
      [
        :hs_read_connection,
        :hs_write_connection
      ].each do |key|
        connection = ActiveRecord::Base.__send__(key).close
      end

      ActiveRecord::Base.__send__ :hs_reset_opened_indexes
    end

    it "should reconnect to handlersocket for read" do
      expect(ActiveRecord::Base.hs_reconnect!).to be

      expect{
        klass.hsfind_by_id 1
      }.not_to raise_error
    end

    it "should reconnect to handlersocket for write" do
      expect(ActiveRecord::Base.hs_reconnect!).to be

      expect{
        klass.hscreate :name => "Test", :age => "1", :status => true
      }.not_to raise_error
    end

    it "should reset opened indexes" do
      expect(ActiveRecord::Base.hs_reconnect!).to be

      expect(ActiveRecord::Base.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).not_to be
      expect(ActiveRecord::Base.__send__(:hs_indexes)[another_klass.__send__(:hs_index_key, "id")][:opened]).not_to be
    end
  end

  describe "hs_active?" do
    context "when connected" do
      before :each do
        # open index
        klass.hsfind_by_id 1
      end

      it "should return true when connected" do
        expect(ActiveRecord::Base.hs_active?).to be
      end
    end

    context "when read closed" do
      before :each do
        ActiveRecord::Base.__send__(:hs_read_connection).close
      end

      after :each do
        ActiveRecord::Base.hs_reconnect!
      end

      it "should return false" do
        expect(ActiveRecord::Base.hs_active?).not_to be
      end
    end

    context "when write closed" do
      before :each do
        ActiveRecord::Base.__send__(:hs_write_connection).close
      end

      after :each do
        ActiveRecord::Base.hs_reconnect!
      end

      it "should return false" do
        expect(ActiveRecord::Base.hs_active?).not_to be
      end
    end
  end

  describe "hs_establish_connection" do
    context "when no name given" do
      before :each do
        @original_connections = ActiveRecord::Base.__send__ :hs_connections
        ActiveRecordHandlerSocket::Connection::PrivateMethods.__send__ :class_variable_set, :@@hs_connections, {}
      end

      after :each do
        ActiveRecordHandlerSocket::Connection::PrivateMethods.__send__ :class_variable_set, :@@hs_connections, @original_connections
      end

      it "should add read connection" do
        ActiveRecord::Base.__send__ :hs_establish_connection
        expect(ActiveRecord::Base.__send__(:hs_connections)[:read]).to be_kind_of(HandlerSocket)
      end

      it "should add write connection" do
        ActiveRecord::Base.__send__ :hs_establish_connection
        expect(ActiveRecord::Base.__send__(:hs_connections)[:write]).to be_kind_of(HandlerSocket)
      end
    end

    context "when read connection" do
      before :each do
        @original_connections = ActiveRecord::Base.__send__ :hs_connections
        ActiveRecordHandlerSocket::Connection::PrivateMethods.__send__ :class_variable_set, :@@hs_connections, {}
      end

      after :each do
        ActiveRecordHandlerSocket::Connection::PrivateMethods.__send__ :class_variable_set, :@@hs_connections, @original_connections
      end

      it "should add read connection" do
        ActiveRecord::Base.__send__ :hs_establish_connection, :read
        expect(ActiveRecord::Base.__send__(:hs_connections)[:read]).to be_kind_of(HandlerSocket)
      end

      it "should add write connection" do
        ActiveRecord::Base.__send__ :hs_establish_connection, :write
        expect(ActiveRecord::Base.__send__(:hs_connections)[:write]).to be_kind_of(HandlerSocket)
      end
    end

    context "when unknown configuration name given" do
      it "should raise error" do
        expect{
          ActiveRecord::Base.__send__ :hs_establish_connection, "test_hs_read"
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "hs_read_connection" do
    it "should return handlersocket" do
      expect(ActiveRecord::Base.__send__(:hs_read_connection)).to be_kind_of(HandlerSocket)
    end
  end

  describe "hs_write_connection" do
    it "should return handlersocket" do
      expect(ActiveRecord::Base.__send__(:hs_write_connection)).to be_kind_of(HandlerSocket)
    end
  end

  describe "hs_open_index" do
    context "when index opened" do
      before :each do
        klass.hsfind_by_id 1
      end

      it "should just return" do
        expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).to be

        expect(klass.__send__(:hs_open_index, klass.__send__(:hs_index_key, "id"))).to be_nil
      end
    end

    context "when open index" do
      before :each do
        ActiveRecord::Base.__send__ :hs_reconnect!
      end

      it "should return true and mark opened" do
        expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).not_to be

        expect(klass.__send__(:hs_open_index, klass.__send__(:hs_index_key, "id"))).to be

        expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).to be
      end
    end

    context "when open write index" do
      before :each do
        ActiveRecord::Base.__send__ :hs_reconnect!
      end

      it "should return true and mark opened" do
        expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_writer_key)][:opened]).not_to be

        expect(klass.__send__(:hs_open_index, klass.__send__(:hs_index_writer_key))).to be

        expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_writer_key)][:opened]).to be
      end
    end

    context "when invalid result" do
      before :each do
        ActiveRecord::Base.__send__ :hs_reconnect!
        Hobby.hsfind_by_id 1

        stub_object ActiveRecord::Base.__send__(:hs_read_connection), :open_index, 2
        stub_object ActiveRecord::Base.__send__(:hs_read_connection), :error, "err"
      end

      it "should raise error" do
        expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).not_to be
        expect(another_klass.__send__(:hs_indexes)[another_klass.__send__(:hs_index_key, "id")][:opened]).to be

        expect{
          klass.__send__ :hs_open_index, klass.__send__(:hs_index_key, "id")
        }.to raise_error(ArgumentError)

        expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).not_to be
        expect(another_klass.__send__(:hs_indexes)[another_klass.__send__(:hs_index_key, "id")][:opened]).to be
      end
    end

    context "when connection error" do
      before :each do
        ActiveRecord::Base.__send__ :hs_reconnect!
        another_klass.hsfind_by_id 1

        stub_object(ActiveRecord::Base.__send__(:hs_read_connection), :open_index, -1)
        stub_object(ActiveRecord::Base.__send__(:hs_read_connection), :error, "connection lost")
      end

      it "should raise error" do
        expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).not_to be
        expect(another_klass.__send__(:hs_indexes)[another_klass.__send__(:hs_index_key, "id")][:opened]).to be

        expect{
          klass.__send__ :hs_open_index, klass.__send__(:hs_index_key, "id")
        }.to raise_error(ActiveRecordHandlerSocket::CannotConnectError)

        expect(klass.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).not_to be
        expect(another_klass.__send__(:hs_indexes)[another_klass.__send__(:hs_index_key, "id")][:opened]).not_to be
      end
    end
  end
end

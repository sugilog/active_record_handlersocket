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
      ActiveRecord::Base.__send__(:hs_read_connection).close
      ActiveRecord::Base.__send__(:hs_reset_opened_indexes)
    end

    it "should reconnect to handlersocket" do
      expect(ActiveRecord::Base.hs_reconnect!).to be
      expect{
        klass.hsfind_by_id(1)
      }.not_to raise_error(ActiveRecordHandlerSocket::CannotConnectError)
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
        klass.hsfind_by_id(1)
      end

      it "should return true when connected" do
        expect(ActiveRecord::Base.hs_active?).to be
      end
    end

    context "when closed" do
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
  end

  describe "hs_establish_connection" do
    context "when no name given" do
      before :each do
        @original_connections = ActiveRecord::Base.__send__(:hs_connections)
        ActiveRecordHandlerSocket::Connection::PrivateMethods.__send__(:class_variable_set, :@@hs_connections, {})
      end

      after :each do
        ActiveRecordHandlerSocket::Connection::PrivateMethods.__send__(:class_variable_set, :@@hs_connections, @original_connections)
      end

      it "should add read connection" do
        ActiveRecord::Base.__send__(:hs_establish_connection)
        expect(ActiveRecord::Base.__send__(:hs_connections)[:read]).to be_kind_of(HandlerSocket)
      end
    end

    context "when read connection" do
      before :each do
        @original_connections = ActiveRecord::Base.__send__(:hs_connections)
        ActiveRecordHandlerSocket::Connection::PrivateMethods.__send__(:class_variable_set, :@@hs_connections, {})
      end

      after :each do
        ActiveRecordHandlerSocket::Connection::PrivateMethods.__send__(:class_variable_set, :@@hs_connections, @original_connections)
      end

      it "should add read connection" do
        ActiveRecord::Base.__send__(:hs_establish_connection, "test_hs_read")
        expect(ActiveRecord::Base.__send__(:hs_connections)[:read]).to be_kind_of(HandlerSocket)
      end
    end

    context "when unknown configuration name given" do
      it "should raise error" do
        expect{
          ActiveRecord::Base.__send__(:hs_establish_connection, "production_hs_read")
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "hs_read_connection" do
    it "should return handlersocket" do
      expect(ActiveRecord::Base.__send__(:hs_read_connection)).to be_kind_of(HandlerSocket)
    end
  end
end

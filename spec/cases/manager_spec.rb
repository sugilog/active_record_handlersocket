require 'spec_helper'

describe "ManagerSpec" do
  let :klass do
    Person
  end

  let :another_klass do
    Hobby
  end

  describe "module attributes" do
    describe "hs_indexes" do
      it "should be private" do
        expect{
          klass.hs_indexes
        }.to raise_error(NoMethodError)
      end

      it "should not writable" do
        expect{
          klass.__send__(:hs_indexes=, {})
        }.to raise_error(NoMethodError)
      end
    end

    describe "hs_index_count_cache" do
      it "should be private" do
        expect{
          klass.hs_index_count_cache
        }.to raise_error(NoMethodError)
      end

      it "should not writable" do
        expect{
          klass.__send__(:hs_index_count_cache=, 0)
        }.to raise_error(NoMethodError)
      end
    end
  end

  describe "handlersocket" do
    it "should not overwrite by another class" do
      expect(ActiveRecord::Base.__send__(:hs_indexes).has_key?(klass.__send__(:hs_index_key, "id"))).to be
      expect(ActiveRecord::Base.__send__(:hs_indexes).has_key?(another_klass.__send__(:hs_index_key, "id"))).to be
    end

    it "should not increment id by each set" do
      initial_count = klass.__send__(:hs_index_count_cache)
      klass.__send__(:handlersocket, "test_id", "PRIMARY", ["id"])
      expect(ActiveRecord::Base.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "test_id")][:id]).to eql(initial_count + 1)
      another_klass.__send__(:handlersocket, "test_id", "PRIMARY", ["id"])
      expect(ActiveRecord::Base.__send__(:hs_indexes)[another_klass.__send__(:hs_index_key, "test_id")][:id]).to eql(initial_count + 2)
      klass.__send__(:handlersocket, "test_id", "PRIMARY", ["id"])
      expect(ActiveRecord::Base.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "test_id")][:id]).to eql(initial_count + 3)
    end
  end

  describe "hs_index_key" do
    it "should be private method" do
      expect{
        klass.hs_index_key("bar")
      }.to raise_error(NoMethodError)
    end

    it "should concat class name and key name" do
      expect(klass.__send__(:hs_index_key, "bar")).to eql(klass.__send__(:hs_index_key, "bar"))
      expect(another_klass.__send__(:hs_index_key, "baz")).to eql(another_klass.__send__(:hs_index_key, "baz"))
    end
  end

  describe "hs_fetch_key" do
    it "should be private method" do
      expect{
        klass.hs_fetch_key("id")
      }.to raise_error(NoMethodError)
    end

    it "should fetch setting" do
      setting = klass.__send__(:hs_fetch_key, klass.__send__(:hs_index_key, "id"))
      expect(setting[:id]).to be_kind_of(Fixnum)
      expect(setting[:index]).to eql("PRIMARY")
      expect(setting[:fields]).to eql(["id", "name", "age", "status"])
      expect(setting[:opened]).not_to be
    end

    it "should require index_key not just a key" do
      expect{
        klass.__send__(:hs_fetch_key, "id")
      }.to raise_error(ActiveRecordHandlerSocket::UnknownIndexError)
    end

    it "should raise error with unknown key given" do
      expect{
        klass.__send__(:hs_fetch_key, klass.__send__(:hs_index_key, "name"))
      }.to raise_error(ActiveRecordHandlerSocket::UnknownIndexError)
    end

    it "should include unknown key in error message" do
      message = ""

      begin
        klass.__send__(:hs_fetch_key, klass.__send__(:hs_index_key, "name"))
      rescue ActiveRecordHandlerSocket::UnknownIndexError => e
        message = e.message
      end

      expect(message).to include(klass.__send__(:hs_index_key, "name"))
    end
  end

  describe "hs_index_count" do
    it "should be private method" do
      expect{
        klass.hs_index_count
      }.to raise_error(NoMethodError)
    end

    it "should increment hs_index_count_cache" do
      initial_count = klass.__send__(:hs_index_count_cache)
      klass.__send__(:hs_index_count)
      expect(klass.__send__(:hs_index_count_cache)).to eql(initial_count + 1)
      klass.__send__(:hs_index_count)
      expect(klass.__send__(:hs_index_count_cache)).to eql(initial_count + 2)
    end
  end

  describe "hs_reset_opened_index" do
    it "should mark not opened for all index settings" do
      klass.hsfind_by_id(1)
      another_klass.hsfind_by_id(1)

      expect(ActiveRecord::Base.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).to be
      expect(ActiveRecord::Base.__send__(:hs_indexes)[another_klass.__send__(:hs_index_key, "id")][:opened]).to be

      klass.__send__(:hs_reset_opened_indexes)

      expect(ActiveRecord::Base.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "id")][:opened]).not_to be
      expect(ActiveRecord::Base.__send__(:hs_indexes)[another_klass.__send__(:hs_index_key, "id")][:opened]).not_to be
    end
  end
end

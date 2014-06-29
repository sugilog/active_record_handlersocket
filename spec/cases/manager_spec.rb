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

    it "should increment id by each set" do
      initial_count = klass.__send__(:hs_index_count_cache)
      klass.__send__(:handlersocket, "test_id", "PRIMARY", :columns => ["id"])
      expect(ActiveRecord::Base.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "test_id")][:id]).to eql(initial_count + 1)
      another_klass.__send__(:handlersocket, "test_id", "PRIMARY", :columns => ["id"])
      expect(ActiveRecord::Base.__send__(:hs_indexes)[another_klass.__send__(:hs_index_key, "test_id")][:id]).to eql(initial_count + 2)
      klass.__send__(:handlersocket, "test_id", "PRIMARY", :columns => ["id"])
      expect(ActiveRecord::Base.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "test_id")][:id]).to eql(initial_count + 3)
    end

    it "should warn key updating" do
      klass.__send__(:handlersocket, "test_id", "PRIMARY", :columns => ["id"])
      klass.__send__(:handlersocket, "test_id", "PRIMARY", :columns => ["id"])

      warning_log.rewind
      warned = warning_log.read.chomp

      expect(warned).to match(/#{klass.name} handlersocket: test_id was updated/)
    end

    it "should be allow deprecated argument" do
      klass.__send__(:handlersocket, "test_id", "PRIMARY", ["id"])
      expect(ActiveRecord::Base.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "test_id")][:fields]).to eql(["id"])
    end

    it "should warn deprecated argument" do
      klass.__send__(:handlersocket, "test_id", "PRIMARY", ["id"])

      warning_log.rewind
      warned = warning_log.read.chomp

      expect(warned).to match(/^DEPRECATION WARNING/)
    end

    it "should be all columns for columns is not specified" do
      klass.__send__(:handlersocket, "test_id", "PRIMARY")
      expect(ActiveRecord::Base.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "test_id")][:fields]).to eql(klass.column_names)
    end

    it "should be columns to string" do
      klass.__send__(:handlersocket, "test_id", :columns => [:name, :age])
      expect(ActiveRecord::Base.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "test_id")][:fields]).to eql(["name", "age"])
    end

    it "can call alias 'hs_reader'" do
      klass.__send__(:hs_reader, "test_id", "PRIMARY")
      expect(ActiveRecord::Base.__send__(:hs_indexes)[klass.__send__(:hs_index_key, "test_id")][:fields]).to eql(klass.column_names)
    end
  end

  describe "hs_writer" do
    it "should not overwrite by another class" do
      expect(ActiveRecord::Base.__send__(:hs_indexes).has_key?(klass.__send__(:hs_index_writer_key))).to be
      expect(ActiveRecord::Base.__send__(:hs_indexes).has_key?(another_klass.__send__(:hs_index_writer_key))).to be
    end

    it "should increment id by each set" do
      initial_count = klass.__send__(:hs_index_count_cache)
      klass.__send__(:hs_writer)
      expect(ActiveRecord::Base.__send__(:hs_indexes)[klass.__send__(:hs_index_writer_key)][:id]).to eql(initial_count + 1)
      another_klass.__send__(:hs_writer)
      expect(ActiveRecord::Base.__send__(:hs_indexes)[another_klass.__send__(:hs_index_writer_key)][:id]).to eql(initial_count + 2)
      klass.__send__(:hs_writer)
      expect(ActiveRecord::Base.__send__(:hs_indexes)[klass.__send__(:hs_index_writer_key)][:id]).to eql(initial_count + 3)
    end

    it "should warn key updating" do
      klass.__send__(:hs_writer)

      warning_log.rewind
      warned = warning_log.read.chomp

      expect(warned).to match(/#{klass.name} handlersocket: __writer__ was updated/)
    end

    it "should be not allow deprecated argument" do
      expect{
        klass.__send__(:hs_writer, ["id"])
      }.to raise_error(TypeError)
    end

    it "should be all columns without primary key for columns is not specified" do
      klass.__send__(:hs_writer)
      expect(ActiveRecord::Base.__send__(:hs_indexes)[klass.__send__(:hs_index_writer_key)][:fields]).to eql(klass.column_names - [klass.primary_key])
    end

    it "should be columns to string" do
      klass.__send__(:hs_writer, :columns => [:name, :age])
      expect(ActiveRecord::Base.__send__(:hs_indexes)[klass.__send__(:hs_index_writer_key)][:fields]).to eql(["name", "age"])
    end
  end
end

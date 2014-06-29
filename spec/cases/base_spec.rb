require 'spec_helper'

describe ActiveRecord::Base do
  let :klass do
    Person
  end

  let :another_klass do
    Hobby
  end

  let :connection do
    ActiveRecord::Base.hs_connection
  end

  describe "hs_reader" do
    context "when same key from another model" do
      describe "Person:id" do
        subject do
          index_key = connection.index_key klass, :id
          setting = connection.fetch index_key
          setting[:fields]
        end

        it "should have Person columns" do
          expect(subject).to eql(%W[id name age status])
        end
      end

      describe "Hobby:id" do
        subject do
          index_key = connection.index_key another_klass, :id
          setting = connection.fetch index_key
          setting[:fields]
        end

        it "should have Hobby columns" do
          expect(subject).to eql(%W[id person_id title])
        end
      end
    end

    context "when columns options" do
      before :each do
        klass.hs_reader :test, "PRIMARY", :columns => %W[id name]
      end

      subject do
        index_key = connection.index_key klass, :test
        setting = connection.fetch index_key
        setting[:fields]
      end

      it "should have given columns" do
        expect(subject).to eql(%W[id name])
      end
    end
  end

  describe "hs_writer" do
    context "when same key from another model" do
      describe "Person:__writer__" do
        subject do
          index_key = connection.index_writer_key klass
          setting = connection.fetch index_key
          setting[:fields]
        end

        it "should have Person columns" do
          expect(subject).to eql(%W[name age status])
        end
      end

      describe "Hobby:__writer__" do
        subject do
          index_key = connection.index_writer_key another_klass
          setting = connection.fetch index_key
          setting[:fields]
        end

        it "should have Hobby columns" do
          expect(subject).to eql(%W[person_id title created_at updated_at])
        end
      end
    end

    context "when columns options" do
      before :each do
        klass.hs_writer :columns => %W[id name]
      end

      subject do
        index_key = connection.index_writer_key klass
        setting = connection.fetch index_key
        setting[:fields]
      end

      it "should have given columns without primary key" do
        expect(subject).to eql(%W[name])
      end
    end

    describe "index fixed" do
      subject do
        index_key = connection.index_writer_key klass
        setting = connection.fetch index_key
        setting[:index]
      end

      it do
        expect(subject).to eql("PRIMARY")
      end
    end
  end
end

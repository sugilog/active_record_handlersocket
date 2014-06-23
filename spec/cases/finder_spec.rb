require 'spec_helper'

describe "FinderSpec" do
  let :klass do
    Person
  end

  before :each do
    @bob = FactoryGirl.create(:bob)
    FactoryGirl.create(:pharrell)
  end

  describe "finder" do
    context "when defined by handlersocket" do
      before :each do
        klass.delete_all
      end

      context "for :first" do
        it "should call hsfind with method_missing" do
          expect(klass).not_to respond_to(:hsfind_by_id)
          expect(klass.hsfind_by_id(1)).to be_nil
        end
      end

      context "for :multi" do
        it "should call hsfind with method_missing" do
          expect(klass).not_to respond_to(:hsfind_multi_by_id)
          expect(klass.hsfind_multi_by_id(1)).to be_empty
        end
      end
    end

    context "when before definition by handlersocket" do
      context "for :first" do
        it "should raise error" do
          expect{
            klass.hsfind_by_name("Bob")
          }.to raise_error(ActiveRecordHandlerSocket::UnknownIndexError)
        end
      end

      context "for :multi" do
        it "should raise error" do
          expect{
            klass.hsfind_multi_by_name("Bob")
          }.to raise_error(ActiveRecordHandlerSocket::UnknownIndexError)
        end
      end

      it "should include unknown key in error message" do
        message = ""

        begin
          klass.hsfind_by_name("Bob")
        rescue ActiveRecordHandlerSocket::UnknownIndexError => e
          message = e.message
        end

        expect(message).to include("#{klass.name}:name")
      end
    end

    context "when records exist" do
      context "for :first" do
        it "should get one record by id" do
          person    = klass.find_by_id(1)
          hs_person = klass.hsfind_by_id(1)

          expect(hs_person).to eql(person)
        end

        it "should get nil by unknown id" do
          person    = klass.find_by_id(9)
          hs_person = klass.hsfind_by_id(9)

          expect(person).to be_nil
          expect(hs_person).to be_nil
        end
      end

      context "for :multi" do
        it "should get one record by id" do
          person    = klass.find_all_by_id([1])
          hs_person = klass.hsfind_multi_by_id(1)

          expect(hs_person).to eql(person)
        end

        it "should get some records by ids" do
          people    = klass.find_all_by_id([1, 2])
          hs_people = klass.hsfind_multi_by_id(1, 2)

          expect(hs_people).to eql(people)
        end

        it "should get empty array by unknown id" do
          people    = klass.find_all_by_id([9])
          hs_people = klass.hsfind_multi_by_id(9)

          expect(people).to be_empty
          expect(hs_people).to be_empty
        end
      end
    end

    context "when finder with options" do
      context "for :single" do
        context "with operator option" do
          it "should find greater value record" do
            hs_person = klass.hsfind_by_id(0, :operator => ">")

            expect(hs_person).to be_kind_of(klass)

            hs_person = klass.hsfind_by_id(3, :operator => ">")

            expect(hs_person).to be_nil
          end

          it "should find less value record" do
            person    = klass.find_by_id(2)
            hs_person = klass.hsfind_by_id(3, :operator => "<")

            expect(hs_person).to eql(person)

            hs_person = klass.hsfind_by_id(0, :operator => "<")

            expect(hs_person).to be_nil
          end
        end

        context "with limit option" do
          it "should ignore limit option" do
            person    = klass.find_by_id(2)
            hs_person = klass.hsfind_by_id(3, :operator => "<", :limit => 10)

            expect(hs_person).to eql(person)
            expect(hs_person).not_to be_kind_of(Array)
          end
        end
      end

      context "for :multi" do
        context "with operator option" do
          it "should find greater value record" do
            hs_people = klass.hsfind_multi_by_id(0, :operator => ">")

            expect(hs_people.size).to  eql(1)
            expect(hs_people.first).to be_kind_of(klass)

            hs_people = klass.hsfind_multi_by_id(3, :operator => ">")

            expect(hs_people).to be_empty
          end

          it "should find less value record" do
            people    = klass.find_all_by_id([2])
            hs_people = klass.hsfind_multi_by_id(3, :operator => "<")

            expect(hs_people).to eql(people)

            hs_people = klass.hsfind_multi_by_id(0, :operator => "<")

            expect(hs_people).to be_empty
          end
        end

        context "with limit option" do
          it "should find greater value records" do
            people    = klass.find_all_by_id([1, 2])
            hs_people = klass.hsfind_multi_by_id(0, :operator => ">", :limit => 10)

            expect(hs_people).to eql(people)
          end
        end
      end
    end
  end
end

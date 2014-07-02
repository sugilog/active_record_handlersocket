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

  let! :connection do
    klass.establish_connection ActiveRecord::Base.logger
  end

  before :each do
    @bob      = FactoryGirl.create(:bob)
    @pharrell = FactoryGirl.create(:pharrell)
    @john     = FactoryGirl.create(:john)

    add_index_setting connection
  end

  describe "#select" do
    context "when records exist" do
      context "for :first" do
        it "should get one record by id" do
          person    = model_class.find_by_id(1)
          hs_person = connection.select(model_class, :first, :id, [1])

          expect(hs_person).not_to be_nil
          expect(hs_person).to eql(person)
        end

        it "should get nil by unknown id" do
          person    = model_class.find_by_id(9)
          hs_person = connection.select(model_class, :first, :id, [9])

          expect(person).to be_nil
          expect(hs_person).to be_nil
        end
      end

      context "for :multi" do
        it "should get one record by id" do
          person    = find_all(model_class, :id => 1)
          hs_person = connection.select(model_class, :multi, :id, [1])

          expect(hs_person.size).to eql(1)
          expect(hs_person).to eql(person)
        end

        it "should get some records by ids" do
          people    = find_all(model_class, :id => [1, 2])
          hs_people = connection.select(model_class, :multi, :id, [1, 2])

          expect(hs_people).to eql(people)
        end

        it "should get empty array by unknown id" do
          people    = find_all(model_class, :id => 9)
          hs_people = connection.select(model_class, :multi, :id, [9])

          expect(people).to be_empty
          expect(hs_people).to be_empty
        end
      end
    end

    describe "select with options" do
      context "for :single" do
        context "with '>' operator option" do
          describe "record exists" do
            subject { connection.select model_class, :first, :id, [0, {:operator => ">"}] }

            it { should be_kind_of model_class }
          end

          describe "record not found" do
            subject { connection.select model_class, :first, :id, [3, {:operator => ">"}] }

            it { should be_nil }
          end
        end

        context "with '<' operator option" do
          describe "record exists" do
            let :person do
              model_class.find_by_id 2
            end

            subject { connection.select model_class, :first, :id, [3, {:operator => "<"}] }

            it { should be_kind_of model_class }
            it { should eql person }
          end

          describe "record not found" do
            subject { connection.select model_class, :first, :id, [0, {:operator => "<"}] }

            it { should be_nil }
          end
        end

        context "with each_limit option" do
          let :person do
            model_class.find_by_id 2
          end

          subject { connection.select model_class, :first, :id, [3, {:operator => "<", :each_limit => 10}] }

          it { should_not be_nil }
          it { should eql person }
          it { should_not be_kind_of Array }
        end
      end

      context "for :multi" do
        context "with '>' operator option" do
          describe "records exists" do
            subject { connection.select model_class, :multi, :id, [0, {:operator => ">"}] }

            its(:size)  { should eql 1 }
            its(:first) { should be_kind_of model_class }
          end

          describe "records not found" do
            subject { connection.select model_class, :multi, :id, [3, {:operator => ">"}] }

            it { should be_empty }
          end
        end

        context "with '<' operator option" do
          describe "records exists" do
            let :people do
              find_all model_class, :id => 2
            end

            subject { connection.select model_class, :multi, :id, [3, {:operator => "<"}] }

            it { should eql people }
          end

          describe "records not found" do
            subject { connection.select model_class, :multi, :id, [0, {:operator => "<"}] }

            it { should be_empty }
          end
        end

        context "with each_limit option" do
          let :people do
            find_all model_class, :id => [1, 2, 3]
          end

          subject { connection.select model_class, :multi, :id, [0, {:operator => ">", :each_limit => 10}] }

          it { should eql people }
        end

        context "with discarded limit option" do
          subject { connection.select model_class, :multi, :id, [0, {:operator => ">", :limit => 10}] }

          it { should eql [@bob] }
        end
      end
    end

    describe "with multi column index" do
      context "for :single" do
        context "when use 1st sequence column" do
          let :person do
            model_class.find_by_age(36)
          end

          subject { connection.select model_class, :first, :age_and_status, [36] }

          it { should eql person }
        end

        context "when use all sequence columns" do
          let :person do
            model_class.find_by_age_and_status 36, false
          end

          # XXX: Cannot use `true/false`
          subject { connection.select model_class, :first, :age_and_status, [36, 0] }

          it { should eql person }
        end

        context "when use not 1st sequence column" do
          # XXX: Cannot use `true/false`
          subject { connection.select model_class, :first, :age_and_status, [0] }

          it { should be_nil }
        end
      end

      context "for :multi" do
        context "when use 1st sequence column" do
          it "should select records" do
            people    = find_all(model_class, :age => 36)
            hs_people = connection.select(model_class, :multi, :age_and_status, [36, {:each_limit => 10}])

            expect(hs_people.size).to eql(2)
            expect(hs_people).to eql(people)

            hs_people = connection.select(model_class, :multi, :age_and_status, [[36], {:each_limit => 10}])

            expect(hs_people.size).to eql(2)
            expect(hs_people).to eql(people)
          end
        end

        context "when use all sequence columns" do
          it "should select records" do
            people    = find_all(model_class, :age => 36, :status => false)
            # XXX: Cannot use `true/false`
            hs_people = connection.select(model_class, :multi, :age_and_status, [[36, 0], {:each_limit => 10}])

            expect(hs_people.size).to eql(1)
            expect(hs_people).to eql(people)
          end

          it "should select records by multi condition" do
            people    = [find_all(model_class, :age => 36, :status => false), find_all(model_class, :age => 36, :status => true)].flatten
            # XXX: Cannot use `true/false`
            hs_people = connection.select(model_class, :multi, :age_and_status, [[36, 0], [36, 1], {:each_limit => 10}])

            expect(hs_people.size).to eql(2)
            expect(hs_people).to eql(people)
          end
        end

        context "when use not 1st sequence column" do
          it "should select records" do
            # XXX: Cannot use `true/false`
            hs_people = connection.select(model_class, :multi, :age_and_status, [[0], {:each_limit => 10}])

            expect(hs_people).to be_empty
          end
        end
      end
    end

    describe "with active_record callbacks" do
      context "for :single" do
        it "should work after_find callback" do
          hs_person = connection.select(model_class, :first, :id, [1])
          expect(hs_person.born_year).to eql(Time.now.year - hs_person.age)
          expect(hs_person.instance_variable_get(:@born_year)).to eql(hs_person.born_year)
        end

        it "should work after_initialize callback" do
          hs_person = connection.select(model_class, :first, :id, [1])
          expect(hs_person.family_name).to eql(hs_person.name.split(" ").last)
          expect(hs_person.instance_variable_get(:@family_name)).to eql(hs_person.family_name)
        end
      end

      context "for :multi" do
        it "should work after_find callback" do
          hs_people = connection.select(model_class, :multi, :id, [1, 2])

          hs_person = hs_people[0]
          expect(hs_person.born_year).to eql(Time.now.year - hs_person.age)
          expect(hs_person.instance_variable_get(:@born_year)).to eql(hs_person.born_year)

          hs_person = hs_people[1]
          expect(hs_person.born_year).to eql(Time.now.year - hs_person.age)
          expect(hs_person.instance_variable_get(:@born_year)).to eql(hs_person.born_year)
        end

        it "should work after_initialize callback" do
          hs_people = connection.select(model_class, :multi, :id, [1, 2])

          hs_person = hs_people[0]
          expect(hs_person.family_name).to eql(hs_person.name.split(" ").last)
          expect(hs_person.instance_variable_get(:@family_name)).to eql(hs_person.family_name)

          hs_person = hs_people[1]
          expect(hs_person.family_name).to eql(hs_person.name.split(" ").last)
          expect(hs_person.instance_variable_get(:@family_name)).to eql(hs_person.family_name)
        end
      end
    end

    describe "with connection" do
      before :each do
        connection.reconnect!
      end

      it "should open index before select" do
        expect{
          connection.select(model_class, :first, :id, [1])
        }.not_to raise_error
        expect(connection.indexes[connection.index_key(model_class, :id)][:opened]).to be
      end
    end
  end

  describe "instantiate" do
    context "when valid result" do
      it "should return single record" do
        result = connection.instantiate model_class, connection.index_key(model_class, :id), [0, [["1", "MySQL", "19", "1"]]]

        expect(result.size).to eql(1)

        record = result.first
        expect(record.id).to     eql(1)
        expect(record.name).to   eql("MySQL")
        expect(record.age).to    eql(19)
        expect(record.status).to be
      end

      it "should return multi record" do
        result = connection.instantiate model_class, connection.index_key(model_class, :id), [0, [["1", "MySQL", "19", "1"], ["2", "%#123", "55", "0"]]]

        expect(result.size).to eql(2)

        record = result.first
        expect(record.id).to     eql(1)
        expect(record.name).to   eql("MySQL")
        expect(record.age).to    eql(19)
        expect(record.status).to be

        record = result.last
        expect(record.id).to         eql(2)
        expect(record.name).to       eql("%#123")
        expect(record.age).to        eql(55)
        expect(record.status).not_to be
      end
    end

    context "when invalid result" do
      it "should raise error" do
        expect{
          connection.instantiate model_class, connection.index_key(model_class, :id), [2, "kpnum"]
        }.to raise_error(ArgumentError)
      end
    end

    context "when connection error" do
      before :each do
        connection.select(model_class, :first, :id, [1])
        connection.select(another_model_class, :first, :id, [1])
      end

      it "should raise error and mark opened_index closed" do
        expect(connection.indexes[connection.index_key(model_class, :id)][:opened]).to be
        expect(connection.indexes[connection.index_key(another_model_class, :id)][:opened]).to be

        expect{
          connection.instantiate model_class, connection.index_key(model_class, :id), [-1, "connection lost"]
        }.to raise_error(ActiveRecordHandlerSocket::ConnectionLost)

        expect(connection.indexes[connection.index_key(model_class, :id)][:opened]).not_to be
        expect(connection.indexes[connection.index_key(another_model_class, :id)][:opened]).not_to be
      end
    end
  end
end

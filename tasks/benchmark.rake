require 'benchmark'

namespace :bm do
  desc "prepare benchmark data"
  task :prepare do
    %W[
      delete_records
      reset_auto_increment
      create_records
    ].each do |task|
      Rake::Task["bm:" + task].invoke
    end
  end

  task :reset_auto_increment do
    mysql "ALTER TABLE #{table} AUTO_INCREMENT = 1", :database => database
  end

  task :delete_records do
    mysql "DELETE #{table}", :database => database
  end

  task :create_records do
    records = [*1..1000].map do |i|
      "(" + ["'#{name}'", rand(80), rand(2)].join(",") + ")"
    end

    mysql "INSERT #{table} (name,age,status) VALUES #{records.join(",")}", :database => database
  end

  desc "do benchmark n=iteration_number"
  task :bm do
    RAILS_ENV = "benchmark"
    require './examples/init'

    n = ( ENV['N'] || 100_000 ).to_i

    STDOUT.puts "Benchmark with N=#{n}"

    Benchmark.bm 20 do |x|
      x.report "find_by_id" do
        n.times do
          id = 1 + rand(1000)
          Person.find_by_id id
        end
      end

      x.report "hsfind_by_id" do
        n.times do
          id = 1 + rand(1000)
          Person.hsfind_by_id id
        end
      end

      x.report "hsfind_multi_by_id" do
        n.times do
          id = 1 + rand(1000)
          Person.hsfind_multi_by_id id
        end
      end
    end
  end

  desc "verify benchmark targets"
  task :verify_bm_target do
    RAILS_ENV = "benchmark"
    require './examples/init'

    result = true

    [*1..1000].each do |i|
      unless Person.find_by_id i
        warn "Person id: #{i} not found by find_by_id."
        result = false
      end

      unless Person.hsfind_by_id i
        warn "Person id: #{i} not found by hsfind_by_id."
        result = false
      end
    end

    if result
      STDOUT.puts "All targets verified."
    else
      STDOUT.puts "Check warned log and data."
    end
  end

  def name
    chars = [*"a".."z"] + [*"A".."Z"]

    [*1..8].map{ chars[rand(chars.size)] }.join
  end

  def database
    DATABASES[:benchmark]
  end

  def table
    "people"
  end
end

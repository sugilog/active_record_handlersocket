TABLES = {
  :people  => %W[
    id     int(11)      NOT NULL AUTO_INCREMENT,
    name   varchar(255) DEFAULT '',
    age    int(11)      DEFAULT NULL,
    status tinyint(1)   NOT NULL DEFAULT '1',
    PRIMARY KEY (id)
  ],
  :hobbies => %W[
    id         int(11)          NOT NULL AUTO_INCREMENT,
    person_id  int(11)          NOT NULL,
    title      varchar(255)     NOT NULL DEFAULT '',
    created_at datetime DEFAULT NULL,
    updated_at datetime DEFAULT NULL,
    PRIMARY KEY (id)
  ]
}

INDEXES = {
  :people => [
    {
      :name    => :index_people_on_age_and_status,
      :columns => %W[age status]
    }
  ],
  :hobbies => [
    {
      :name    => :index_hobbies_on_person_id,
      :columns => %W[person_id]
    },
    {
      :name    => :index_hobbies_on_person_id_and_title,
      :columns => %W[person_id title],
      :unique  => true
    }
  ]
}

namespace :db do
  desc "create user for active_record_handler_socket"
  task :create_user do
    mysql "GRANT ALL PRIVILEGES ON *.* TO '#{MYSQL_USER}'@'localhost' WITH GRANT OPTION", :user => "root"
    mysql "SHOW GRANTS FOR 'rails'@'localhost'", :user => "root"
  end

  desc "create databases for active_record_handler_socket"
  task :create_databases do
    DATABASES.each do |_, database|
      mysql "CREATE DATABASE #{database} DEFAULT CHARACTER SET 'utf8'"
    end

    mysql "SHOW DATABASES"
  end

  desc "create tables for active_record_handler_socket"
  task :create_tables do
    DATABASES.each do |_, database|
      TABLES.each do |table, schema|
        mysql "CREATE TABLE #{table} (#{schema.join(" ")}) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8", :database => database
      end

      mysql "SHOW TABLES", :database => database
    end
  end

  desc "create indexes for active_record_handler_socket"
  task :create_indexes do
    DATABASES.each do |_, database|
      INDEXES.each do |table, indexes|
        indexes.each do |config|
          mysql "CREATE #{config[:unique] ? "UNIQUE" : ""} INDEX #{config[:name]} USING btree ON #{table} (#{config[:columns].join(",")})", :database => database
        end

        mysql "SHOW INDEXES FROM #{table}", :database => database
      end
    end
  end

  desc "run db tasks"
  task :prepare do
    %W[
      create_user
      create_databases
      create_tables
      create_indexes
    ].each do |task|
      Rake::Task["db:" + task].invoke
    end
  end

  desc "drop databases"
  task :drop do
    DATABASES.each do |_, database|
      mysql "DROP DATABASE #{database}"
    end
  end
end

desc "connect development database"
task :db do
  sh "mysql -u #{MYSQL_USER} #{DATABASES[:development]}"
end

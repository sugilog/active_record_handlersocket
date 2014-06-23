active_record_handlersocket
===========================

HandlerSocket for ActiveRecord; depends handlersocket gem https://github.com/miyucy/handlersocket


**Underconstruction**

usage
------------------------------------------------------------

Update your `config/database.yml` of rails project. (Available to set database same as AR read/write database.)

```
development_hs_read:
  host:     localhost
  port:     9998
  database: ar_handler_socket
```

Define HandlerSocket index setting on your ActiveReocrd Model.

```
class Person < ActiveRecord::Base
  handlersocket :id, "PRIMARY", %W[id name age]
end
```

Call `hsfind_by_#{key}` of `hsfind_multi_by_#{key}` to get record(s) as ActiveRecord Object.

```
Person.hsfind_by_id(1)
#=> #<Person id: 1, name: "Bob Marley", age: 36>

Person.hsfind_multi_by_id(1, 2)
#=> [
#   #<Person id: 1, name: "Bob Marley", age: 36>,
#   #<Person id: 2, name: "Pharrell Wiiliams", age: 41>
# ]
```


development
------------------------------------------------------------

Dev dependencies

```
mkdir vendor
bundle install --path=vendor
```

Prepare DB

```sh
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'rails'@'localhost' WITH GRANT OPTION"
mysql -u root -e "SHOW GRANTS FOR 'rails'@'localhost'"

+----------------------------------------------------------------------+
| Grants for rails@localhost                                           |
+----------------------------------------------------------------------+
| GRANT ALL PRIVILEGES ON *.* TO 'rails'@'localhost' WITH GRANT OPTION |
+----------------------------------------------------------------------+


mysql -u rails -e "CREATE DATABASE ar_handler_socket DEFAULT CHARACTER SET 'utf8'"
mysql -u rails -e "show databases"

+------------------------------------------+
| Database                                 |
+------------------------------------------+
...
| ar_handler_socket                        |
...
+------------------------------------------+


mysql -u rails ar_handler_socket -e "CREATE TABLE people ( id int(11) NOT NULL AUTO_INCREMENT, name varchar(255) DEFAULT '', age int(11) DEFAULT NULL, status tinyint(1) NOT NULL DEFAULT '1', PRIMARY KEY (id) ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8"
mysql -u rails ar_handler_socket -e "CREATE TABLE hobbies ( id int(11) NOT NULL AUTO_INCREMENT, person_id int(11) NOT NULL, title varchar(255) DEFAULT '', created_at datetime DEFAULT NULL, updated_at datetime DEFAULT NULL, PRIMARY KEY (id), KEY index_hobbies_on_person_id (person_id) ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8"
mysql -u rails ar_handler_socket -e "SHOW TABLES"

+-----------------------------+
| Tables_in_ar_handler_socket |
+-----------------------------+
| hobbies                     |
| people                      |
+-----------------------------+
```


Try example on console

```
bundle exec irb
```

```ruby
require 'example'
#=> true

Person.create(:name => "Bob Marley", :age => 36, :status => false)

Person.find_by_id(1)
#=> #<Person id: 1, name: "Bob Marley", age: 36, status: false>
Person.hsfind_by_id(1)
#=> #<Person id: 1, name: "Bob Marley", age: 36, status: false>
```


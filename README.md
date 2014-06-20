active_record_handlersocket
===========================

HandlerSocket for ActiveRecord; depends handlersocket gem https://github.com/miyucy/handlersocket


**Underconstruction**

usage
------------------------------------------------------------

Include ARHandlerSocket module into model class of ActiveReocrd.

```
class Person < ActiveRecord::Base
  include ActiveRecord::ARHandlerSocket
  handlersocket :id, "PRIMARY", %W[id first_name family_name active]
end
```

Call `hsfind_by_#{key}` of `hsfind_multi_by_#{key}` to get record(s) as ActiveRecord object.

```
Person.hsfind_by_id(1)
#=> #<Person id: 1, first_name: "Bob", family_name: "Marley", age: 36>

Person.hsfind_multi_by_id(1, 2)
#=> [
#   #<Person id: 1, first_name: "Bob", family_name: "Marley", age: 36>,
#   #<Person id: 2, first_name: "Pharrell", family_name: "Wiiliams", age: 41>
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
mysql -u rails ar_handler_socket -e "show tables"

+-----------------------------+
| Tables_in_ar_handler_socket |
+-----------------------------+
| people                      |
+-----------------------------+
```


Try example on console

```
bundle exec irb
```

```ruby
require 'examples/person.rb'
#=> true

Person.create(:name => "Bob Marley", :age => 36, :status => false)

Person.find_by_id(1)
#=> #<Person id: 1, name: "Bob Marley", age: 36, status: false>
Person.hsfind_by_id(1)
#=> #<Person id: 1, name: "Bob Marley", age: 36, status: false>
```


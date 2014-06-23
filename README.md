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
  database: active_record_handler_socket
```

Define HandlerSocket index setting on your ActiveReocrd Model.

```ruby
class Person < ActiveRecord::Base
  handlersocket :id, "PRIMARY", %W[id name age]
end
```

Call `hsfind_by_#{key}` of `hsfind_multi_by_#{key}` to get record(s) as ActiveRecord Object.

```ruby
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

```sh
mkdir vendor
bundle install --path=vendor
```

Prepare DB

```sh
rake db:prepare
```

create following items on MySQL.

 key             | value
-----------------|------------------------------------------
 user            | rails
 database (dev)  | active_record_handler_socket
 database (test) | active_record_handler_socket_test
 tables          | people, hobbies


Try example on console

```sh
bundle exec irb
```

```ruby
require 'examples/init'
#=> true

Person.create(:name => "Bob Marley", :age => 36, :status => false)

Person.find_by_id(1)
#=> #<Person id: 1, name: "Bob Marley", age: 36, status: false>
Person.hsfind_by_id(1)
#=> #<Person id: 1, name: "Bob Marley", age: 36, status: false>
```


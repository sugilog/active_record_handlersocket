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
#<Person id: 1, first_name: "Bob", family_name: "Marley", age: 36>

Person.hsfind_multi_by_id(1, 2)
[
  #<Person id: 1, first_name: "Bob", family_name: "Marley", age: 36>,
  #<Person id: 2, first_name: "Pharrell", family_name: "Wiiliams", age: 41>
]
```


development
------------------------------------------------------------

```
mkdir vendor
bundle install --path=vendor
```

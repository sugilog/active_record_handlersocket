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

Call `find_hs_with_#{key}` of `find_all_hs_with_#{key}` to get records as ActiveRecord object.

```
Person.find_hs_with_id(1)
#<Person id: 1, first_name: "Bob", family_name: "Marley", active: false>

Person.find_all_hs_with_id(1, 2)
[
  #<Person id: 1, first_name: "Bob", family_name: "Marley", active: false>,
  #<Person id: 2, first_name: "Pharrell", family_name: "Wiiliams", active: true>
]
```



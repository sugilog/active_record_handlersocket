FactoryGirl.define do
  factory :bob, :class => Person do
    id      1
    name    "Bob Marley"
    age     36
    status  false
  end

  factory :pharrell, :class => Person do
    id      2
    name    "Pharrell Williams"
    age     41
    status  true
  end

  factory :john, :class => Person do
    id      3
    name    "John Legend"
    age     36
    status  true
  end
end

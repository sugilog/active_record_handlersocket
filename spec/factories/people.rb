FactoryGirl.define do
  factory :bob, :class => Person do
    name    "Bob Marley"
    age     36
    status  false
  end

  factory :pharrell, :class => Person do
    name    "Pharrell Williams"
    age     41
    status  true
  end
end

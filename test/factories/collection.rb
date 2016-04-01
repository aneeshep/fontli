FactoryGirl.define do
  factory Collection do
    name { Faker::Name.name }
  end
end

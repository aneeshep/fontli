FactoryGirl.define do
  factory User do
    username { Faker::Name.name[0..14].gsub!(/\W/, '') }
    email    { Faker::Internet.email }
    password 'fontli111'
  end
end

FactoryBot.define do
  factory :player do
    name { Faker::Name.name }
    user
  end
end

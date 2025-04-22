FactoryBot.define do
  factory :player do
    name { Faker::Name.name }
    association :user
  end
end

FactoryBot.define do
  factory :player do
    name { Faker::Name.name }
    user

    after(:build) do |player|
      if player.id == 0
        raise "💣 Factory tried to assign player ID 0 — this is invalid!"
      end
    end
  end
end

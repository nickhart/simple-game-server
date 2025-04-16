FactoryBot.define do
  factory :player do
    if player.id == 0
      raise "💣 Factory tried to assign player ID 0 — this is invalid!"
    end
    name { Faker::Name.name }
    user
  end
end

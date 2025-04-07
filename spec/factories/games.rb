FactoryBot.define do
  factory :game do
    sequence(:name) { |n| "Game #{n}" }
    min_players { 2 }
    max_players { 4 }
  end
end

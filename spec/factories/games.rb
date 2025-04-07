FactoryBot.define do
  factory :game do
    name { Faker::Game.title }
    min_players { 2 }
    max_players { 2 }

    after(:build) do |game|
      game.game_configuration ||= build(:game_configuration, game: game)
    end
  end
end

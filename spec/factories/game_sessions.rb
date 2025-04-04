FactoryBot.define do
  factory :game_session do
    name { Faker::Game.title }
    status { :waiting }
    min_players { 2 }
    max_players { 2 }
    state { {
      board: Array.new(3) { Array.new(3, '') },
      current_player: 'X'
    } }
    association :game, factory: :game
  end
end 
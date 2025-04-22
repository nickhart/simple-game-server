FactoryBot.define do
  factory :game_session do
    name { Faker::Game.title }
    game
    association :creator, factory: :user

    trait :new_game_state do
      after(:build) do |game_session|
        puts "[FACTORY DEBUG] Applying new_game_state trait to GameSession ##{game_session.object_id}"
      end

      # state { { board: [0, 0, 0] } }
    end

    trait :finished_game_state do
      state { { board: [1, 2, 1], winner: 1 } }
    end
  end
end

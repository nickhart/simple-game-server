FactoryBot.define do
  factory :game do
    name { Faker::Game.title }
    min_players { 2 }
    max_players { 2 }
    association :game_configuration
    state_schema do
      {
        type: "object",
        properties: {
          board: {
            type: "array",
            items: { type: %w[string null] },
            minItems: 9,
            maxItems: 9
          },
          current_player: {
            type: "string",
            enum: %w[X O]
          }
        },
        required: %w[board current_player]
      }
    end
  end
end

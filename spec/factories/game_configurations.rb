FactoryBot.define do
  factory :game_configuration do
    state_schema do
      {
        type: "object",
        properties: {
          board: {
            type: "array",
            items: {
              type: "array",
              items: {
                type: "string",
                enum: ["X", "O", ""]
              }
            }
          },
          current_player: {
            type: "string",
            enum: %w[X O]
          }
        },
        required: %w[board current_player]
      }.deep_stringify_keys
    end
    game
  end
end

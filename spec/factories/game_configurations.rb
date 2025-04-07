FactoryBot.define do
  factory :game_configuration do
    game
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
          },
          winner: {
            type: %w[string null],
            enum: ["X", "O", nil]
          }
        },
        required: %w[board current_player]
      }
    end

    trait :tic_tac_toe do
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
            },
            winner: {
              type: %w[string null],
              enum: ["X", "O", nil]
            }
          },
          required: %w[board current_player]
        }
      end
    end
  end
end

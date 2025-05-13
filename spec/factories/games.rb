FactoryBot.define do
  factory :game do
    sequence(:name) { |n| "Zolite #{n}" }

    state_json_schema { { type: "object", properties: {} }.to_json }

    # trait :without_schema do
    #   state_json_schema { { type: "object", properties: {} }.to_json }
    # end
        
    trait :with_current_turn_schema do
      state_json_schema {
        {
          type: "object",
          properties: {
            current_turn: { type: "integer" }
          },
          required: ["current_turn"]
        }.to_json
      }
    end

    trait :with_board_and_winner_schema do
      state_json_schema {
        {
          type: "object",
          properties: {
            board: {
              type: "array",
              items: { type: "integer", enum: [0, 1, 2] },
              minItems: 0,
              maxItems: 9
            },
            winner: {
              type: "integer",
              enum: [0, 1, 2]
            }
          },
          required: ["board", "winner"],
          additionalProperties: false
        }.to_json
      }
    end
  end
end

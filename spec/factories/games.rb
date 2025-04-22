FactoryBot.define do
  factory :game do
    sequence(:name) { |n| "Zolite #{n}" }
    # name { Faker::Game.title }
    # min_players { 2 }
    # max_players { 2 }
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
        additionalProperties: false
      }.to_json
    }
  end
end

FactoryBot.define do
  factory :game do
    name { Faker::Game.title }
    min_players { 2 }
    max_players { 2 }
    association :game_configuration, factory: :game_configuration
    state_schema { {
      type: 'object',
      properties: {
        board: {
          type: 'array',
          items: { type: ['string', 'null'] },
          minItems: 9,
          maxItems: 9
        },
        current_player: {
          type: 'string',
          enum: ['X', 'O']
        }
      },
      required: ['board', 'current_player']
    } }
  end
end 
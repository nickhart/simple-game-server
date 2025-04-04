FactoryBot.define do
  factory :game_configuration do
    state_schema { {
      type: 'object',
      properties: {
        board: {
          type: 'array',
          items: {
            type: 'array',
            items: {
              type: 'string',
              enum: ['X', 'O', '']
            }
          }
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
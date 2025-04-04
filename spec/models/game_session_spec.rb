require 'rails_helper'

RSpec.describe GameSession, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes', skip: 'Temporarily skipped' do
      game_session = build(:game_session)
      expect(game_session).to be_valid
    end

    it 'is not valid without a name', skip: 'Temporarily skipped' do
      game_session = build(:game_session, name: nil)
      expect(game_session).not_to be_valid
    end

    it 'is not valid without a state', skip: 'Temporarily skipped' do
      game_session = build(:game_session, state: nil)
      expect(game_session).not_to be_valid
    end
  end
end 
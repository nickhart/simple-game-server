require "rails_helper"

RSpec.describe Game, type: :model do
  describe "player limits" do
    it "is valid when min_players is less than max_players" do
      game = build(:game, min_players: 2, max_players: 4)
      expect(game).to be_valid
    end

    it "is valid when min_players equals max_players" do
      game = build(:game, min_players: 4, max_players: 4)
      expect(game).to be_valid
    end

    it "is invalid when min_players is greater than max_players" do
      game = build(:game, min_players: 5, max_players: 4)
      expect(game).not_to be_valid
      expect(game.errors[:max_players]).to include("must be greater than or equal to min_players")
    end

    it "is invalid without min_players" do
      game = build(:game, min_players: nil, max_players: 4)
      expect(game).not_to be_valid
      expect(game.errors[:min_players]).to include("can't be blank")
    end

    it "is invalid without max_players" do
      game = build(:game, min_players: 2, max_players: nil)
      expect(game).not_to be_valid
      expect(game.errors[:max_players]).to include("can't be blank")
    end
  end
end

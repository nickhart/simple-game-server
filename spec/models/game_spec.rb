require "rails_helper"

RSpec.describe Game, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      expect(build(:game)).to be_valid
    end

    describe "name validation" do
      it "is not valid without a name" do
        game = build(:game, name: nil)
        expect(game).not_to be_valid
      end

      it "adds an error message when name is blank" do
        game = build(:game, name: nil)
        game.valid?
        expect(game.errors[:name]).to include("can't be blank")
      end

      it "is not valid with a duplicate name" do
        create(:game, name: "Duplicate")
        game = build(:game, name: "Duplicate")
        expect(game).not_to be_valid
      end

      it "adds an error message when name is duplicate" do
        create(:game, name: "Duplicate")
        game = build(:game, name: "Duplicate")
        game.valid?
        expect(game.errors[:name]).to include("has already been taken")
      end
    end

    describe "min_players validation" do
      it "is not valid without min_players" do
        game = build(:game, min_players: nil)
        expect(game).not_to be_valid
      end

      it "adds an error message when min_players is blank" do
        game = build(:game, min_players: nil)
        game.valid?
        expect(game.errors[:min_players]).to include("can't be blank")
      end

      it "is not valid with min_players less than 1" do
        game = build(:game, min_players: 0)
        expect(game).not_to be_valid
      end

      it "adds an error message when min_players is less than 1" do
        game = build(:game, min_players: 0)
        game.valid?
        expect(game.errors[:min_players]).to include("must be greater than 0")
      end
    end

    describe "max_players validation" do
      it "is not valid without max_players" do
        game = build(:game, max_players: nil)
        expect(game).not_to be_valid
      end

      it "adds an error message when max_players is blank" do
        game = build(:game, max_players: nil)
        game.valid?
        expect(game.errors[:max_players]).to include("can't be blank")
      end

      it "is not valid with max_players greater than MAX_PLAYERS" do
        game = build(:game, max_players: Game::MAX_PLAYERS + 1)
        expect(game).not_to be_valid
      end

      it "adds an error message when max_players exceeds MAX_PLAYERS" do
        game = build(:game, max_players: Game::MAX_PLAYERS + 1)
        game.valid?
        expect(game.errors[:max_players]).to include("must be less than or equal to #{Game::MAX_PLAYERS}")
      end
    end

    describe "max_players vs min_players validation" do
      it "is not valid when max_players is less than min_players" do
        game = build(:game, min_players: 3, max_players: 2)
        expect(game).not_to be_valid
      end

      it "adds an error message when max_players is less than min_players" do
        game = build(:game, min_players: 3, max_players: 2)
        game.valid?
        expect(game.errors[:max_players]).to include("must be greater than or equal to min_players")
      end
    end
  end

  describe "associations" do
    it "has many game_sessions" do
      game = create(:game)
      create_list(:game_session, 3, game: game)
      expect(game.game_sessions.count).to eq(3)
    end
  end
end

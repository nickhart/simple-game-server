require "rails_helper"

RSpec.describe GameSession, type: :model do
  let(:game) { create(:game) }
  let(:creator) { create(:player) }

  describe "validations" do
    it "is valid with valid attributes" do
      game_session = build(:game_session, game: game, creator: creator)
      expect(game_session).to be_valid
    end

    describe "status validation" do
      let(:game_session) { described_class.new(game: game, creator: creator) }

      before { game_session.status = nil }

      it "is not valid" do
        expect(game_session).not_to be_valid
      end

      it "has an error on status" do
        game_session.valid?
        expect(game_session.errors[:status]).to include("can't be blank")
      end
    end

    it "is not valid with an invalid status" do
      expect do
        build(:game_session, game: game, creator: creator, status: :invalid)
      end.to raise_error(ArgumentError, /'invalid' is not a valid status/)
    end
  end

  describe "player limits validation" do
    let(:game_session) { described_class.new(creator: creator) }

    context "when min_players is missing" do
      before do
        game_session.min_players = nil
        game_session.valid?
      end

      it "is not valid" do
        expect(game_session).not_to be_valid
      end

      it "has an error on min_players" do
        expect(game_session.errors[:min_players]).to include("can't be blank")
      end
    end

    context "when max_players is missing" do
      before do
        game_session.max_players = nil
        game_session.valid?
      end

      it "is not valid" do
        expect(game_session).not_to be_valid
      end

      it "has an error on max_players" do
        expect(game_session.errors[:max_players]).to include("can't be blank")
      end
    end

    context "when max_players is less than min_players" do
      before do
        game_session.min_players = 3
        game_session.max_players = 2
        game_session.valid?
      end

      it "is not valid" do
        expect(game_session).not_to be_valid
      end

      it "has an error on max_players" do
        expect(game_session.errors[:max_players]).to include("must be greater than or equal to min_players")
      end
    end
  end

  describe "defaults" do
    it "sets default status to waiting" do
      game_session = described_class.new
      expect(game_session.status).to eq("waiting")
    end

    it "sets default state to empty hash" do
      game_session = described_class.new
      game_session.valid?
      expect(game_session.state).to eq({})
    end

    describe "game player limits" do
      let(:game) { create(:game, min_players: 3, max_players: 4) }
      let(:game_session) { described_class.new(game: game) }

      before { game_session.valid? }

      it "uses game's min_players" do
        expect(game_session.min_players).to eq(game.min_players)
      end

      it "uses game's max_players" do
        expect(game_session.max_players).to eq(game.max_players)
      end
    end

    describe "database defaults" do
      let(:game_session) { described_class.new }

      before { game_session.valid? }

      it "uses database default min_players" do
        expect(game_session.min_players).to eq(2)
      end

      it "uses database default max_players" do
        expect(game_session.max_players).to eq(4)
      end
    end
  end
end

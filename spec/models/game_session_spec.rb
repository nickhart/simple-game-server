require "rails_helper"

RSpec.describe GameSession, type: :model do
  let(:game) { create(:game, min_players: 2, max_players: 4) }
  let(:user) { create(:user) }
  let(:creator) { user.player }

  describe "validations" do
    it "is valid with valid attributes" do
      game_session = build(:game_session, :new_game_state, game: game, creator: creator, status: :waiting)
      game_session.valid? # trigger set_defaults
      expect(game_session).to be_valid
    end

    it "is valid with a finished game state" do
      game_session = build(:game_session, :finished_game_state, game: game, creator: creator, status: :waiting)
      game_session.valid? # trigger set_defaults
      expect(game_session).to be_valid
    end

    it "is not valid with a malformed state" do
      game_session = build(:game_session, game: game, creator: creator, state: { board: ["a", "b", "c"] })
      game_session.valid?
      expect(game_session.errors[:state]).to include(I18n.t("activerecord.errors.models.game_session.attributes.state.invalid_state"))
    end

    it "is not valid with an invalid status" do
      expect do
        build(:game_session, game: game, creator: creator, status: :invalid)
      end.to raise_error(ArgumentError, /'invalid' is not a valid status/)
    end

    it "is invalid when the state does not match the game's state_json_schema" do
      schema = {
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

      game = create(:game, state_json_schema: schema)
      game_session = GameSession.new(
        game: game,
        creator: create(:user).player,
        state: { board: [-1, 100, 13] }
      )
      
      expect(game_session.valid?).to be(false)
      expect(game_session.errors[:state]).to include(I18n.t("activerecord.errors.models.game_session.attributes.state.invalid_state"))

    end    
  end

  describe "player limits validation" do
    let(:game) { create(:game, min_players: 2, max_players: 4) }
    let(:game_session) { described_class.new(creator: creator, game: game) }

    context "when min_players is missing" do
      before do
        game_session.min_players = nil
        game_session.valid?
      end

      it "allows creation when record is new" do
        expect(game_session.errors[:min_players]).to be_empty
      end
    end

    context "when max_players is missing" do
      before do
        game_session.max_players = nil
        game_session.valid?
      end

      it "allows creation when record is new" do
        expect(game_session.errors[:max_players]).to be_empty
      end
    end

    context "when max_players is less than min_players" do
      it "is not valid" do
        game_session = build(:game_session, :new_game_state, game: game, creator: creator, status: :waiting)
        game_session.min_players = 3
        game_session.max_players = 2
        game_session.save(validate: false)
        game_session.valid?
        expect(game_session).not_to be_valid
      end

      it "has an error on max_players" do
        game_session = build(:game_session, :new_game_state, game: game, creator: creator, status: :waiting)
        game_session.min_players = 3
        game_session.max_players = 2
        game_session.save(validate: false)
        game_session.valid?
        expect(game_session.errors[:max_players]).to include(I18n.t("activerecord.errors.models.game_session.attributes.max_players.must_be_greater_than_or_equal_to_min_players"))
      end
    end
  end

  describe "defaults" do
    it "sets default status to waiting" do
      game_session = described_class.new
      game_session.valid?
      expect(game_session).to be_status_waiting
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

    describe "inheriting player limits" do
      let(:game) { create(:game, min_players: 3, max_players: 5) }
    
      it "inherits min_players and max_players from the game if not set" do
        session = GameSession.create!(game: game, creator: create(:user).player)
        expect(session.min_players).to eq(3)
        expect(session.max_players).to eq(5)
      end
    end
  end
end

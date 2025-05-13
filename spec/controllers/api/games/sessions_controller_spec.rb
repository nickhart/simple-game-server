require "rails_helper"

RSpec.describe Api::Games::SessionsController, type: :controller, truncation: true do
  let(:user_and_player) do
    create_user_with_player!
  end
  let(:user) { user_and_player[0] }
  let(:player) { user_and_player[1] }
  let(:game) { create(:game) }

  # Example for finished game state validation:
  # describe "GameSession validations is valid with a finished game state" do
  #   let(:game) { create(:game, :with_board_and_winner_schema) }
  #   # ... rest of the spec ...
  # end
  let(:game_session) { create(:game_session, creator: player, game: game) }


  describe "GET #index" do
    context "when authenticated" do
      before do
        sign_in(user)
        get :index, params: { game_id: game.id }, format: :json
      end

      it "returns success" do
        expect(response).to have_http_status(:success)
      end

      it "returns all game sessions" do
        expect(response.parsed_body["data"]).to be_an(Array)
      end
    end

    context "when not authenticated" do
      before { get :index, params: { game_id: game.id }, format: :json }

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET #show" do
    context "when authenticated" do
      before do
        sign_in(user)
        game_session.players << player
        get :show, params: { id: game_session.id, game_id: game.id }, format: :json
      end

      it "returns success" do
        expect(response).to have_http_status(:success)
      end

      it "returns the game session" do
        json = response.parsed_body
        expect(json["data"]["id"]).to eq(game_session.id)
      end
    end

    context "when not authenticated" do
      before { get :show, params: { id: game_session.id, game_id: game.id }, format: :json }

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        game_id: game.id,
        game_session: {
          min_players: 2,
          max_players: 4
        },
        format: :json
      }
    end

    context "when authenticated" do
      before { sign_in(user) }

      it "creates a new game session" do
        expect do
          post :create, params: valid_params
        end.to change(GameSession, :count).by(1)
      end

      it "returns created status" do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
      end

      it "adds the creator as a player" do
        post :create, params: valid_params
        game_session = GameSession.last
        expect(game_session.players).to include(player)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        post :create, params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PUT #update" do
    let(:valid_params) do
      {
        id: game_session.id,
        game_id: game.id,
        game_session: {
          state: { current_turn: 1 }
        },
        format: :json
      }
    end

    context "when authenticated" do
      before do
        sign_in(user)
        game_session.players << player
      end

      it "updates the game session" do
        put :update, params: valid_params
        expect(response).to have_http_status(:success)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        put :update, params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated and providing current_player_index" do
      let(:valid_index) { 0 }
      let(:valid_params_with_index) do
        {
          id: game_session.id,
          game_id: game.id,
          game_session: {
            state: { current_turn: 1 },
            current_player_index: valid_index
          },
          format: :json
        }
      end

      before do
        sign_in(user)
        # ensure at least one other player to avoid single-player wrap issues
        game_session.players << player
      end

      it "accepts the provided valid index and returns it" do
        put :update, params: valid_params_with_index
        expect(response).to have_http_status(:success)
        body = response.parsed_body["data"]
        expect(body["current_player_index"]).to eq(valid_index)
      end
    end

    context "when authenticated and providing out-of-range current_player_index" do
      let(:invalid_index) { game_session.players.count + 5 }
      let(:invalid_params) do
        {
          id: game_session.id,
          game_id: game.id,
          game_session: {
            state: { current_turn: 1 },
            current_player_index: invalid_index
          },
          format: :json
        }
      end

      before do
        sign_in(user)
        game_session.players << player
      end

      it "returns unprocessable_entity" do
        put :update, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to include("Invalid current_player_index")
      end
    end

    context "when authenticated and omitting current_player_index" do
      let(:no_index_params) do
        {
          id: game_session.id,
          game_id: game.id,
          game_session: {
            state: { current_turn: 1 }
          },
          format: :json
        }
      end

      before do
        sign_in(user)
        # set a known starting index and two players to test wrap behavior
        game_session.update(current_player_index: 0)
        game_session.players << player
        game_session.players << create(:player)
        # Mark the session as started so updates are allowed
        game_session.update!(status: :active)
        puts "game_session: #{game_session.inspect}"
        puts "  >> players now: #{game_session.players.map(&:id)}"
      end

      it "auto-increments and wraps current_player_index" do
        expect(game_session.reload.current_player_index).to eq(0)
        put :update, params: no_index_params
        expect(response).to have_http_status(:success)
        body = response.parsed_body["data"]
        puts "params: #{no_index_params}"
        puts "body: #{body}"
        # next index should be (0+1)%player_count => 1
        expect(body["current_player_index"]).to eq(1)
      end
    end
  end

  describe "POST #join" do
    let(:join_params) do
      {
        id: game_session.id,
        game_id: game.id,
        format: :json
      }
    end

    context "when authenticated" do
      let(:other_user_and_player) do
        create_user_with_player!
      end      
      let(:other_user) { other_user_and_player[0] }
      let(:other_player) { other_user_and_player[1] }

      before do
        sign_in(other_user)
      end

      it "adds the player to the game session" do
        post :join, params: join_params
        expect(response).to have_http_status(:success)
        expect(game_session.reload.players).to include(other_player)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        post :join, params: join_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE #leave" do
    let(:leave_params) do
      {
        id: game_session.id,
        game_id: game.id,
        format: :json
      }
    end

    context "when authenticated" do
      before do
        sign_in(user)
        game_session.players << player
      end

      it "removes the player from the game session" do
        delete :leave, params: leave_params
        expect(response).to have_http_status(:success)
        expect(game_session.reload.players).not_to include(player)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        delete :leave, params: leave_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST #start" do
    let(:start_params) do
      {
        id: game_session.id,
        game_id: game.id,
        format: :json
      }
    end

    context "when authenticated as creator" do
      before do
        sign_in(user)
        game_session.players << player
        game_session.players << create(:player) # ensure player count meets min_players
      end

      it "starts the game session if requirements are met" do
        post :start, params: start_params
        expect(response).to have_http_status(:ok)
        expect(game_session.reload.status).to eq("active")
      end
    end

    context "when authenticated as non-creator" do
      let(:other_user_and_player) { create_user_with_player! }
      let(:other_user) { other_user_and_player[0] }

      before do
        sign_in(other_user)
        game_session.players << player
      end

      it "returns forbidden" do
        post :start, params: start_params
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        post :start, params: start_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when session is not in waiting state" do
      before do
        sign_in(user)
        game_session.update(status: :active)
        game_session.players << player
      end

      it "does not allow re-starting the session" do
        post :start, params: start_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when player count is invalid" do
      before do
        sign_in(user)
        game_session.update(min_players: 2, max_players: 2)
        game_session.players = [] # Not enough players
      end

      it "returns unprocessable_entity" do
        post :start, params: start_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end

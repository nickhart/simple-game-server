require "rails_helper"

RSpec.describe Api::Games::SessionsController, type: :controller, truncation: true do
  let(:user_and_player) do
    create_user_with_player!
  end
  let(:user) { user_and_player[0] }
  let(:player) { user_and_player[1] }
  let(:game) { create(:game) }
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

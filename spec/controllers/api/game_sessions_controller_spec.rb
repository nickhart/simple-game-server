require "rails_helper"

RSpec.describe Api::GameSessionsController, type: :controller do
  let(:user) { create(:user) }
  let(:player) { create(:player, user: user) }
  let(:game) { create(:game) }
  let(:game_session) { create(:game_session, creator: player, game: game) }

  describe "GET #index" do
    context "when authenticated" do
      before do
        sign_in(user)
        get :index, format: :json
      end

      it "returns success" do
        expect(response).to have_http_status(:success)
      end

      it "returns all game sessions" do
        expect(response.parsed_body).to be_an(Array)
      end
    end

    context "when not authenticated" do
      before { get :index, format: :json }

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET #show" do
    context "when authenticated" do
      before do
        sign_in(user)
        get :show, params: { id: game_session.id }, format: :json
      end

      it "returns success" do
        expect(response).to have_http_status(:success)
      end

      it "returns the game session" do
        json = response.parsed_body
        expect(json["id"]).to eq(game_session.id)
      end
    end

    context "when not authenticated" do
      before { get :show, params: { id: game_session.id }, format: :json }

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        player_id: player.id,
        game_session: {
          game_id: game.id,
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
        game_session: {
          state: { current_turn: 1 }
        },
        format: :json
      }
    end

    context "when authenticated" do
      before { sign_in(user) }

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
    let(:other_player) { create(:player) }
    let(:join_params) do
      {
        id: game_session.id,
        player_id: other_player.id,
        format: :json
      }
    end

    context "when authenticated" do
      before { sign_in(other_player.user) }

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
        player_id: player.id,
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
        player_id: player.id,
        format: :json
      }
    end

    context "when authenticated as creator" do
      let(:other_player) { create(:player) }

      before do
        sign_in(user)
        game_session.update!(min_players: 2, max_players: 4, status: "waiting")
        game_session.players << player
        game_session.players << other_player
      end

      it "starts the game session" do
        post :start, params: start_params
        expect(response).to have_http_status(:success)
        expect(game_session.reload).not_to be_waiting
      end
    end

    context "when authenticated but not creator" do
      let(:other_player) { create(:player) }

      before do
        sign_in(other_player.user)
        game_session.players << other_player
      end

      it "returns unauthorized" do
        post :start, params: start_params.merge(player_id: other_player.id)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        post :start, params: start_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

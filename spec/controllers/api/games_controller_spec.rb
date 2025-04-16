require "rails_helper"

RSpec.describe Api::GamesController, type: :controller do
  let(:admin_user) { create(:user, :admin) }
  let(:player_user) { create(:user) }
  let(:valid_attributes) do
    {
      name: "Test Game",
      min_players: 2,
      max_players: 4,
      state_json_schema: {
        type: "object",
        properties: {
          board: { type: "array", items: { type: "integer", enum: [0, 1, 2] } }
        }
      }.to_json
    }
  end

  before do
    request.headers["Content-Type"] = "application/json"
  end

  describe "GET #index" do
    include_context "authenticated as player"
    it "returns a list of games" do
      create_list(:game, 3)
      get :index
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.length).to be >= 3
    end

    it "returns unauthorized when not authenticated" do
      request.headers['Authorization'] = nil
      get :index
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET #show" do
    context "when authenticated as player" do
      include_context "authenticated as player"
      let!(:game) { create(:game) }

      it "returns the game" do
        get :show, params: { id: game.id }
        expect(response).to have_http_status(:ok)

        puts "Response body: #{response.body}"        
        expect(response.parsed_body["data"]["id"]).to eq(game.id)
    end

      it "returns not found for a non-existent game" do
        get :show, params: { id: -1 }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
        let!(:game) { create(:game) }

        it "returns unauthorized" do
        request.headers["Authorization"] = nil
        get :show, params: { id: game.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST #create" do
    context "as admin" do
      include_context "authenticated as admin"

      it "creates a new game" do
        expect {
          post :create, params: valid_attributes, as: :json
        }.to change(Game, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "returns unprocessable entity when missing params" do
        post :create, params: { name: "Test Game" }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "as player" do
      include_context "authenticated as player"

      it "returns forbidden" do
        post :create, params: valid_attributes, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    it "returns unauthorized when not authenticated" do
      post :create, params: valid_attributes, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH #update" do
    context "as admin" do
      include_context "authenticated as admin"
      let!(:game) { create(:game) }

      it "updates the game" do
        patch :update, params: { id: game.id, name: "Updated Game" }, as: :json
        expect(response).to have_http_status(:ok)
        expect(game.reload.name).to eq("Updated Game")
      end

      it "returns unprocessable entity when missing params" do
        patch :update, params: { id: game.id, game: { name: nil } }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "as player" do
      include_context "authenticated as player"

      it "returns forbidden" do
        patch :update, params: { id: game.id, name: "Hacked Game" }, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    let!(:game) { create(:game) }

    it "returns unauthorized when not authenticated" do
      patch :update, params: { id: game.id, name: "Hacked Game" }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE #destroy" do
    context "as admin" do
      include_context "authenticated as admin"
      let!(:game) { create(:game) }

      it "deletes the game" do
        delete :destroy, params: { id: game.id }
        expect(response).to have_http_status(:no_content)
        expect(Game.exists?(game.id)).to be false
      end
    end

    context "as player" do
      include_context "authenticated as player"
      let!(:game) { create(:game) }

      it "returns forbidden" do
        delete :destroy, params: { id: game.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    let!(:game) { create(:game) }

    it "returns unauthorized when not authenticated" do
      delete :destroy, params: { id: game.id }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

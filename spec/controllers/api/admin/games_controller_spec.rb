require "rails_helper"

RSpec.describe Api::Admin::GamesController, type: :controller do
  routes { Rails.application.routes }
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

  describe "POST #create" do
    context "as admin" do
      include_context "authenticated as admin"

      it "creates a new game" do
        expect {
          post :create, params: { game: valid_attributes }, as: :json
        }.to change(Game, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "returns unprocessable entity when missing params" do
        post :create, params: { game: { name: "Test Game" } }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns unprocessable entity for invalid JSON schema" do
        post :create, params: { game: valid_attributes.merge(state_json_schema: "not-json") }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH #update" do
    context "as admin" do
      include_context "authenticated as admin"
      let!(:game) { create(:game) }

      it "updates the game" do
        patch :update, params: { id: game.id, game: { name: "Updated Game" } }, as: :json
        expect(response).to have_http_status(:ok)
        expect(game.reload.name).to eq("Updated Game")
      end

      it "returns unprocessable entity when missing params" do
        patch :update, params: { id: game.id, game: { name: nil } }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns not found for non-existent game" do
        patch :update, params: { id: -1, game: { name: "Updated" } }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    let!(:game) { create(:game) }

    it "returns unauthorized when not authenticated" do
      patch :update, params: { id: game.id, game: { name: "Hacked Game" } }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE #destroy" do
    context "as admin" do
      include_context "authenticated as admin"
      let!(:game) { create(:game) }

      it "deletes the game" do
        delete :destroy, params: { id: game.id }, as: :json
        expect(response).to have_http_status(:no_content)
        expect(Game.exists?(game.id)).to be false
      end

      it "returns not found when trying to delete a non-existent game" do
        delete :destroy, params: { id: -1 }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    let!(:game) { create(:game) }

    it "returns unauthorized when not authenticated" do
      delete :destroy, params: { id: game.id }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

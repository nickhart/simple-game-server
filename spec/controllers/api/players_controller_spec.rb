require "rails_helper"

RSpec.describe Api::PlayersController, type: :controller do
  describe "POST #create" do
    let(:user) { create(:user, role: "player") }

    before do
      sign_in user
    end

    context "when the user does not have a player yet" do
      it "creates a new player and returns success" do
        expect {
          post :create, params: { player: { name: "TestPlayer" } }, as: :json
        }.to change(Player, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["data"]["name"]).to eq("TestPlayer")
      end
    end

    context "when the user already has a player" do
      before do
        create(:player, user: user)
      end

      it "does not create a second player" do
        expect {
          post :create, as: :json
        }.not_to change(Player, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to match(/Player already exists/)
      end
    end

    context "when unauthenticated" do
      it "returns unauthorized" do
        sign_out user
        post :create, params: { player: { name: "Hacker" } }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET #show" do
    let(:user) { create(:user, role: "player") }
    let!(:player) { create(:player, user: user, name: "MePlayer") }

    context "as the authenticated user" do
      before { sign_in user }

      it "returns the current player's info when using :me" do
        get :show, params: { id: "me" }, as: :json
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["data"]["name"]).to eq("MePlayer")
      end

      it "does not allow accessing another player's record" do
        other_player = create(:player)
        get :show, params: { id: other_player.id }, as: :json
        expect(response).to have_http_status(:forbidden).or have_http_status(:not_found)
      end
    end

    context "when unauthenticated" do
      it "returns unauthorized for :me" do
        get :show, params: { id: "me" }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

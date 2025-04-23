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

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)["error"]).to match(/Player already exists/)
      end
    end
  end
end

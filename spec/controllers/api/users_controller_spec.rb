require "rails_helper"

RSpec.describe Api::UsersController, type: :controller do
  describe "POST #create" do
    context "with valid parameters" do
      it "creates a new player user without an associated player record" do
        post :create, params: {
          user: {
            email: "player@example.com",
            password: "securepass",
            password_confirmation: "securepass"
          }
        }, as: :json

        expect(response).to have_http_status(:created)
        user = User.find_by(email: "player@example.com")
        expect(user).not_to be_nil
        expect(user.role).to eq("player")
        # A Player is created separately after user registration, not automatically.
        expect(user.player).to be_nil
      end
    end

    context "with invalid parameters" do
      it "does not create a user and returns errors" do
        post :create, params: {
          user: {
            email: "",
            password: "short",
            password_confirmation: "no_match"
          }
        }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body["errors"]).to be_an(Array)
      end
    end
  end

  describe "GET #show" do
    context "when accessing /me with valid auth" do
      it "returns the current user" do
        user = User.create!(email: "me@example.com", password: "securepass", role: "player")
        access_token = Token.create_access_token(user)
        token = user.to_jwt(access_token)

        request.headers["Authorization"] = "Bearer #{token}"
        get :show, params: { id: "me" }, as: :json

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["data"]["email"]).to eq("me@example.com")
      end
    end
  end
end
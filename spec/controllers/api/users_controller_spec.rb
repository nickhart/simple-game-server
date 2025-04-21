require "rails_helper"

RSpec.describe Api::UsersController, type: :controller do
  describe "POST #create" do
    context "with valid parameters" do
      it "creates a new player user" do
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
end
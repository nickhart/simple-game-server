require "rails_helper"

RSpec.describe Api::SessionsController, type: :controller do
  before do
    request.env["CONTENT_TYPE"] = "application/json"
  end

  let(:user) { create(:user, password: "password123") }
  let(:valid_credentials) do
    {
      email: user.email,
      password: user.password
    }
  end
  let(:invalid_credentials) do
    {
      email: user.email,
      password: "wrongpassword"
    }
  end

  describe "POST #create" do
    context "with valid credentials" do
      before do
        post :create, params: { email: user.email, password: "password123" }, format: :json
      end

      it "returns a JWT token" do
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["access_token"]).to be_present
        expect(json["refresh_token"]).to be_present
        expect(json["user"]["id"]).to eq(user.id)
        expect(json["user"]["email"]).to eq(user.email)
      end

      it "creates access and refresh tokens" do
        expect(Token.access_tokens.count).to eq(1)
        expect(Token.refresh_tokens.count).to eq(1)
      end
    end

    context "with invalid credentials" do
      before do
        post :create, params: { email: user.email, password: "wrong" }, format: :json
      end

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid email or password")
      end

      it "does not create any tokens" do
        expect(Token.count).to eq(0)
      end
    end
  end

  describe "POST #refresh" do
    let(:refresh_token) { create(:token, :refresh, user: user) }
    let(:jwt_token) do
      payload = {
        jti: refresh_token.jti,
        user_id: user.id,
        token_version: user.token_version,
        exp: refresh_token.expires_at.to_i
      }
      JWT.encode(payload, Rails.application.credentials.secret_key_base)
    end

    context "with valid refresh token" do
      before do
        post :refresh, params: { refresh_token: jwt_token }, format: :json
      end

      it "returns a new access token" do
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["access_token"]).to be_present
      end

      it "creates a new access token" do
        expect(Token.access_tokens.count).to eq(1)
      end
    end

    context "with expired refresh token" do
      let(:refresh_token) { create(:token, :refresh, :expired, user: user) }

      before do
        post :refresh, params: { refresh_token: jwt_token }, format: :json
      end

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid refresh token")
      end
    end

    context "with invalid refresh token" do
      before do
        post :refresh, params: { refresh_token: "invalid" }, format: :json
      end

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid refresh token")
      end
    end
  end

  describe "DELETE #destroy" do
    context "when authenticated" do
      before do
        sign_in(user)
        delete :destroy, params: { id: user.id }, format: :json
      end

      it "invalidates the token" do
        expect(response).to have_http_status(:no_content)
        expect(user.reload.token_version).to eq(2)
      end
    end

    context "when not authenticated" do
      before do
        delete :destroy, params: { id: user.id }, format: :json
      end

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

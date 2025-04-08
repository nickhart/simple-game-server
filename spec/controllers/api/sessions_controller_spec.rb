require "rails_helper"

RSpec.describe Api::SessionsController, type: :controller do
  before do
    request.env["CONTENT_TYPE"] = "application/json"
  end

  let(:user) { create(:user) }
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
      it "returns a JWT token" do
        post :create, params: valid_credentials
        expect(response).to have_http_status(:success)
        expect(json_response).to have_key("token")
        expect(json_response).to have_key("user")
        expect(json_response["user"]).to include("id", "email")
      end
    end

    context "with invalid credentials" do
      it "returns unauthorized" do
        post :create, params: invalid_credentials
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to have_key("error")
      end
    end
  end

  describe "DELETE #destroy" do
    context "when authenticated" do
      before { sign_in(user) }

      it "invalidates the token" do
        expect { delete :destroy }.to change { user.reload.token_version }.by(1)
        expect(response).to have_http_status(:no_content)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        delete :destroy
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

require "rails_helper"

RSpec.describe Api::Admin::UsersController, type: :controller do
  include_context "authenticated as admin"

  let!(:user) { create(:user) }

  describe "POST #create" do
    before do
      User.destroy_all
    end

    it "creates the first user as an admin" do
      post :create, params: { user: { email: "admin@example.com", password: "securepass" } }, as: :json
      expect(response).to have_http_status(:created)
      user = User.find_by(email: "admin@example.com")
      expect(user).not_to be_nil
      expect(user.reload.role).to eq("admin")
    end

    it "rejects subsequent admin user creation" do
      admin = User.create!(email: "admin@example.com", password: "securepass", role: "admin")
      token = generate_token_for(admin)
      request.headers["Authorization"] = "Bearer #{token}"

      post :create, params: { user: { email: "user@example.com", password: "securepass" } }, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]).to eq("Admin user creation is not allowed")
    end
  end

  describe "GET #index" do
    it "returns a list of users" do
      get :index, as: :json    
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to be_an(Array)
    end
  end

  describe "GET #show" do
    it "returns the user" do
      get :show, params: { id: user.id }, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["id"]).to eq(user.id)
    end
  end

  describe "PATCH #update" do
    it "updates the user email" do
      patch :update, params: { id: user.id, user: { email: "new@example.com" } }, as: :json
      expect(response).to have_http_status(:ok)
      expect(user.reload.email).to eq("new@example.com")
    end
  end

  describe "POST #make_admin" do
    it "promotes the user to admin" do
      post :make_admin, params: { id: user.id }, as: :json
      expect(response).to have_http_status(:ok)
      expect(user.reload.role).to eq("admin")
    end

    describe "POST #make_admin as non-admin" do
      it "returns forbidden" do
        non_admin = User.create!(email: "user@example.com", password: "securepass", role: "player")
        token = generate_token_for(non_admin)
        request.headers["Authorization"] = "Bearer #{token}"

        post :make_admin, params: { id: user.id }, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST #make_admin idempotency" do
      before { user.make_admin! }

      it "succeeds when promoting an already-admin user" do
        post :make_admin, params: { id: user.id }, as: :json
        expect(response).to have_http_status(:ok)
        expect(user.reload.role).to eq("admin")
      end
    end
  end

  describe "POST #remove_admin" do
    before { user.make_admin! }

    it "demotes the user from admin" do
      post :remove_admin, params: { id: user.id }, as: :json
      expect(response).to have_http_status(:ok)
      expect(user.reload.role).to eq("player")
    end

    describe "POST #remove_admin as non-admin" do
      it "returns forbidden" do
        non_admin = User.create!(email: "user@example.com", password: "securepass", role: "player")
        token = generate_token_for(non_admin)
        request.headers["Authorization"] = "Bearer #{token}"

        post :remove_admin, params: { id: user.id }, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST #remove_admin idempotency" do
      it "succeeds when demoting an already-non-admin user" do
        post :remove_admin, params: { id: user.id }, as: :json
        expect(response).to have_http_status(:ok)
        expect(user.reload.role).to eq("player")
      end
    end
  end
end
require "rails_helper"

RSpec.describe Api::GamesController, type: :controller do
  include Devise::Test::ControllerHelpers

  let(:admin_user) { create(:user, role: "admin") }
  let(:valid_attributes) do
    {
      name: "Test Game",
      min_players: 2,
      max_players: 4
    }
  end
  let(:invalid_attributes) { { name: "nil", min_players: 0, max_players: 1 } }

  before do
    request.headers["Authorization"] = "Bearer #{generate_token(admin_user)}"
    request.headers["Accept"] = "application/json"
    request.headers["Content-Type"] = "application/json"
    sign_in admin_user
  end

  describe "GET #index" do
    it "returns a success response" do
      create(:game)
      get :index, format: :json
      expect(response).to be_successful
    end

    it "returns all games" do
      create_list(:game, 3)
      get :index, format: :json
      expect(response.parsed_body.size).to eq(3)
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      game = create(:game)
      get :show, params: { id: game.id }, format: :json
      expect(response).to be_successful
    end

    it "returns the requested game" do
      game = create(:game)
      get :show, params: { id: game.id }, format: :json
      expect(response.parsed_body["id"]).to eq(game.id)
    end

    it "returns not found for non-existent game" do
      get :show, params: { id: 999 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Game" do
        expect do
          post :create, params: { game: valid_attributes }, format: :json
        end.to change(Game, :count).by(1)
      end

      it "returns a created status" do
        post :create, params: { game: valid_attributes }, format: :json
        expect(response).to have_http_status(:created)
      end

      it "returns JSON content type" do
        post :create, params: { game: valid_attributes }, format: :json
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end

    context "with invalid params" do
      it "returns an unprocessable entity status" do
        post :create, params: { game: invalid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns JSON content type" do
        post :create, params: { game: invalid_attributes }, format: :json
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end
  end

  describe "PUT #update" do
    let(:game) { create(:game) }

    context "with valid params" do
      let(:new_attributes) do
        {
          name: "New Game Name",
          min_players: 2,
          max_players: 4
        }
      end

      it "updates the requested game" do
        put :update, params: { id: game.id, game: new_attributes }, format: :json
        game.reload
        expect(game.name).to eq("New Game Name")
      end

      it "returns a success status" do
        put :update, params: { id: game.id, game: new_attributes }, format: :json
        expect(response).to be_successful
      end

      it "returns JSON content type" do
        put :update, params: { id: game.id, game: new_attributes }, format: :json
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end

    context "with invalid params" do
      it "returns an unprocessable entity status" do
        put :update, params: { id: game.id, game: invalid_attributes }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns JSON content type" do
        put :update, params: { id: game.id, game: invalid_attributes }, format: :json
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested game" do
      game = create(:game)
      expect do
        delete :destroy, params: { id: game.id }, format: :json
      end.to change(Game, :count).by(-1)
    end

    it "returns no content" do
      game = create(:game)
      delete :destroy, params: { id: game.id }, format: :json
      expect(response).to have_http_status(:no_content)
    end
  end

  private

  def generate_token(user)
    payload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      exp: 24.hours.from_now.to_i,
      iat: Time.current.to_i,
      jti: SecureRandom.uuid
    }
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end
end

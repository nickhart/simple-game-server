require "rails_helper"

RSpec.describe Api::GamesController, type: :controller do
  let(:user) { create(:user) }
  let(:valid_attributes) { attributes_for(:game) }
  let(:invalid_attributes) { { name: nil, min_players: 0, max_players: 1 } }

  before do
    request.headers["Authorization"] = "Bearer #{generate_token(user)}"
  end

  describe "GET #index" do
    it "returns a success response" do
      create(:game)
      get :index
      expect(response).to be_successful
    end

    it "returns all games" do
      games = create_list(:game, 3)
      get :index
      expect(JSON.parse(response.body).size).to eq(3)
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      game = create(:game)
      get :show, params: { id: game.id }
      expect(response).to be_successful
    end

    it "returns the requested game" do
      game = create(:game)
      get :show, params: { id: game.id }
      expect(JSON.parse(response.body)["id"]).to eq(game.id)
    end

    it "returns not found for non-existent game" do
      get :show, params: { id: 999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Game" do
        expect {
          post :create, params: { game: valid_attributes }
        }.to change(Game, :count).by(1)
      end

      it "renders a JSON response with the new game" do
        post :create, params: { game: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new game" do
        post :create, params: { game: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end
  end

  describe "PUT #update" do
    let(:game) { create(:game) }

    context "with valid params" do
      let(:new_attributes) { { name: "New Game Name" } }

      it "updates the requested game" do
        put :update, params: { id: game.id, game: new_attributes }
        game.reload
        expect(game.name).to eq("New Game Name")
      end

      it "renders a JSON response with the game" do
        put :update, params: { id: game.id, game: valid_attributes }
        expect(response).to be_successful
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the game" do
        put :update, params: { id: game.id, game: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested game" do
      game = create(:game)
      expect {
        delete :destroy, params: { id: game.id }
      }.to change(Game, :count).by(-1)
    end

    it "returns no content" do
      game = create(:game)
      delete :destroy, params: { id: game.id }
      expect(response).to have_http_status(:no_content)
    end
  end

  private

  def generate_token(user)
    JWT.encode(
      { sub: user.id, exp: 24.hours.from_now.to_i },
      Rails.application.credentials.secret_key_base
    )
  end
end 
RSpec.describe "End-to-end game flow", type: :request do
    let!(:admin) { create(:user, role: :admin) }
    let!(:player1) { create(:user, role: :player) }
    let!(:player2) { create(:user, role: :player) }
  
    it "runs through a full game lifecycle" do
      # Admin login
      post "/api/auth/login", params: { email: admin.email, password: "password" }
      admin_token = JSON.parse(response.body)["access_token"]
  
      # Create Game
      post "/api/games", headers: { Authorization: "Bearer #{admin_token}" }, params: {
        game: { name: "TestGame", state_json_schema: {}.to_json }
      }
      game_id = JSON.parse(response.body)["data"]["id"]
  
      # Player1 login
      post "/api/auth/login", params: { email: player1.email, password: "password" }
      p1_token = JSON.parse(response.body)["access_token"]
      # Player2 login
      post "/api/auth/login", params: { email: player2.email, password: "password" }
      p2_token = JSON.parse(response.body)["access_token"]
  
      # Player1 creates a session
      post "/api/game_sessions", headers: { Authorization: "Bearer #{p1_token}" }, params: {
        player_id: player1.id,
        game_session: { game_id: game_id, min_players: 2, max_players: 2 }
      }
      session_id = JSON.parse(response.body)["data"]["id"]
  
      # Player2 joins
      post "/api/game_sessions/#{session_id}/join", headers: { Authorization: "Bearer #{p2_token}" }, params: { player_id: player2.id }
  
      # Player1 starts
      post "/api/game_sessions/#{session_id}/start", headers: { Authorization: "Bearer #{p1_token}" }, params: { player_id: player1.id }
  
      # Game updates here...
  
      # Admin deletes game
      delete "/api/games/#{game_id}", headers: { Authorization: "Bearer #{admin_token}" }
  
      expect(response).to have_http_status(:no_content)
    end
  end
  
require "rails_helper"

puts "Manually loading UsersController..."
begin
  Api::UsersController
  puts "Loaded: #{Api::UsersController.name}"
rescue NameError => e
  puts "FAILED TO LOAD: #{e.message}"
end

RSpec.describe "End-to-end game flow", type: :request, truncation: true do

  it "runs through a full game lifecycle" do

    # Step 1: Create the admin
    post "/api/admin/users", params: {
      user: {
        email: "admin@example.com",
        password: "secret",
        password_confirmation: "secret"
      }
    }, as: :json
    puts "Admin creation response status: #{response.status}"
    puts "Admin creation response body: #{response.body}"
    expect(response).to have_http_status(:created)

    # Step 2: Log in as admin
    post "/api/sessions", params: {
      email: "admin@example.com",
      password: "secret"
    }, as: :json
    admin_token = JSON.parse(response.body)["access_token"]

    # Step 3: Create a game
    headers = { "Authorization" => "Bearer #{admin_token}" }
    post "/api/games", params: {
      game: {
        name: "Zolite",
        min_players: 2,
        max_players: 4,
        state_json_schema: {
          type: "object",
          properties: {
            score: { type: "integer" }
          },
          required: ["score"]
        }.to_json
      }
    }, headers: headers, as: :json
    expect(response).to have_http_status(:created)
    game_id = JSON.parse(response.body)["id"]

    # Step 4: Register two players

    puts "Next player ID: #{ActiveRecord::Base.connection.select_value("SELECT nextval('players_id_seq')")}"

    post "/api/users", params: {
      user: {
        email: "player1@example.com",
        password: "secret",
        password_confirmation: "secret"
      }
    }, as: :json
    puts "Player1 creation status: #{response.status}, body: #{response.body}"
    expect(response).to have_http_status(:created)

    puts "Next player ID: #{ActiveRecord::Base.connection.select_value("SELECT nextval('players_id_seq')")}"

    post "/api/users", params: {
      user: {
        email: "player2@example.com",
        password: "secret",
        password_confirmation: "secret"
      }
    }, as: :json
    puts "Player2 creation status: #{response.status}, body: #{response.body}"
    expect(response).to have_http_status(:created)

    # Step 5: Log in both players
    post "/api/sessions", params: {
      email: "player1@example.com",
      password: "secret"
    }, as: :json
    player1_token = JSON.parse(response.body)["access_token"]

    post "/api/sessions", params: {
      email: "player2@example.com",
      password: "secret"
    }, as: :json
    player2_token = JSON.parse(response.body)["access_token"]

    # Step 6: Create a game session as player1
    headers = { "Authorization" => "Bearer #{player1_token}" }
    post "/api/game_sessions", params: {
      game_session: {
        game_id: game_id
      }
    }, headers: headers, as: :json
    puts "GameSession creation status: #{response.status}, body: #{response.body}"
    expect(response).to have_http_status(:created)
    session_id = JSON.parse(response.body)["data"]["id"]

    # Step 7: Player 2 joins
    headers = { "Authorization" => "Bearer #{player2_token}" }
    post "/api/game_sessions/#{session_id}/join", headers: headers, as: :json
    expect(response).to have_http_status(:ok)

    # Step 8: Player 1 starts session
    headers = { "Authorization" => "Bearer #{player1_token}" }
    post "/api/game_sessions/#{session_id}/start", headers: headers, as: :json
    expect(response).to have_http_status(:ok)

    # Step 9: Players take turns updating game state
    2.times do |i|
      headers = { "Authorization" => "Bearer #{i.even? ? player1_token : player2_token}" }
      patch "/api/game_sessions/#{session_id}", params: {
        game_session: {
          state: { score: (i + 1) * 10 }
        }
      }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end

    # Step 10: Player 1 ends game
    # headers = { "Authorization" => "Bearer #{player1_token}" }
    # post "/api/game_sessions/#{session_id}/finish", headers: headers, as: :json
    # puts "tried to hit route: /api/game_sessions/#{session_id}/finish"
    # expect(response).to have_http_status(:ok)

    # Step 11: Admin deletes the game
    # Sanity check: confirm admin token and role
    puts "Admin token: #{admin_token}"
    get "/api/users/me", headers: { "Authorization" => "Bearer #{admin_token}" }, as: :json
    puts "Admin profile response: #{response.body}"
    puts "DELETE response status: #{response.status}"
    puts "DELETE response summary: #{JSON.parse(response.body).inspect rescue response.body.truncate(300)}"
    
    # Attempt to delete game
    headers = { "Authorization" => "Bearer #{admin_token}" }
    puts "Sending DELETE to /api/games/#{game_id} with headers: #{headers.inspect}"
    delete "/api/games/#{game_id}", headers: headers, as: :json
    puts "DELETE response status: #{response.status}, body: #{response.body}"
    puts "📣 Final GET game_session status: #{response.status}, body: #{response.body}"
    expect(response).to have_http_status(:no_content)
  end
end
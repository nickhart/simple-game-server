require "test_helper"

module Api
  class GameSessionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:one)
      @player = players(:one)
      @game_session = game_sessions(:one)
      @token = generate_jwt_token(@user)
    end

    # Authentication Tests
    test "should register new user" do
      post api_players_url,
           params: {
             user: {
               email: "new@example.com",
               password: "password123",
               password_confirmation: "password123"
             }
           }
      assert_response :created
      assert_not_nil JSON.parse(response.body)["token"]
    end

    test "should login existing user" do
      post api_sessions_url,
           params: {
             email: @user.email,
             password: "password123"
           }
      assert_response :success
      assert_not_nil JSON.parse(response.body)["token"]
    end

    # Game Session Creation Tests
    test "should create game session" do
      assert_difference("GameSession.count") do
        post api_game_sessions_url,
             params: {
               game_session: {
                 min_players: 2,
                 max_players: 4
               },
               player_id: @player.id
             },
             headers: { "Authorization" => "Bearer #{@token}" }
      end
      assert_response :created
      assert_not_nil assigns(:game_session)
      assert_equal @player.id, assigns(:game_session).creator_id
    end

    test "should not create game session with invalid player count" do
      assert_no_difference("GameSession.count") do
        post api_game_sessions_url,
             params: {
               game_session: {
                 min_players: 4,
                 max_players: 2
               },
               player_id: @player.id
             },
             headers: { "Authorization" => "Bearer #{@token}" }
      end
      assert_response :unprocessable_entity
    end

    # Game Session Cleanup Tests
    test "should cleanup old waiting games" do
      old_game = GameSession.create!(
        min_players: 2,
        max_players: 4,
        created_at: 2.days.ago,
        status: "waiting"
      )

      delete cleanup_api_game_sessions_url,
             params: { before: 1.day.ago.iso8601 },
             headers: { "Authorization" => "Bearer #{@token}" }
      
      assert_response :success
      assert_not GameSession.exists?(old_game.id)
    end

    test "should not cleanup active games" do
      active_game = GameSession.create!(
        min_players: 2,
        max_players: 4,
        created_at: 2.days.ago,
        status: "active"
      )
      active_game.players << @player

      delete cleanup_api_game_sessions_url,
             params: { before: 1.day.ago.iso8601 },
             headers: { "Authorization" => "Bearer #{@token}" }
      
      assert_response :success
      assert GameSession.exists?(active_game.id)
    end

    # Game Session Update Tests
    test "should update game state and advance turn when active" do
      @game_session.players << @player
      @game_session.players << players(:two)
      @game_session.update(creator_id: @player.id, status: "active")

      initial_player_index = @game_session.current_player_index
      
      put api_game_session_url(@game_session),
          params: {
            game_session: {
              state: { board: [1, 0, 0, 0, 0, 0, 0, 0, 0] }
            }
          },
          headers: { "Authorization" => "Bearer #{@token}" }
      
      assert_response :success
      @game_session.reload
      assert_equal [1, 0, 0, 0, 0, 0, 0, 0, 0], @game_session.state["board"]
      assert_not_equal initial_player_index, @game_session.current_player_index
    end

    test "should not advance turn when game is finished" do
      @game_session.players << @player
      @game_session.players << players(:two)
      @game_session.update(creator_id: @player.id, status: "finished")

      initial_player_index = @game_session.current_player_index
      
      put api_game_session_url(@game_session),
          params: {
            game_session: {
              state: { board: [1, 0, 0, 0, 0, 0, 0, 0, 0] }
            }
          },
          headers: { "Authorization" => "Bearer #{@token}" }
      
      assert_response :success
      @game_session.reload
      assert_equal initial_player_index, @game_session.current_player_index
    end

    # Game Session State Validation Tests
    test "should maintain state between updates" do
      @game_session.players << @player
      @game_session.players << players(:two)
      @game_session.update(creator_id: @player.id, status: "active")

      initial_state = { board: [1, 0, 0, 0, 0, 0, 0, 0, 0], current_player: 1 }
      @game_session.state = initial_state
      @game_session.save!

      get api_game_session_url(@game_session),
          headers: { "Authorization" => "Bearer #{@token}" }
      
      assert_response :success
      response_state = JSON.parse(response.body)["state"]
      assert_equal initial_state["board"], response_state["board"]
      assert_equal initial_state["current_player"], response_state["current_player"]
    end

    # Player Management Tests
    test "should join waiting game" do
      assert_difference("@game_session.players.count") do
        post join_api_game_session_url(@game_session),
             params: { player_id: @player.id },
             headers: { "Authorization" => "Bearer #{@token}" }
      end
      assert_response :success
    end

    test "should not join active game" do
      @game_session.update(status: "active")
      
      assert_no_difference("@game_session.players.count") do
        post join_api_game_session_url(@game_session),
             params: { player_id: @player.id },
             headers: { "Authorization" => "Bearer #{@token}" }
      end
      assert_response :unprocessable_entity
    end

    test "should not join full game" do
      @game_session.players << players(:two)
      @game_session.players << players(:three)
      @game_session.players << players(:four)
      
      assert_no_difference("@game_session.players.count") do
        post join_api_game_session_url(@game_session),
             params: { player_id: @player.id },
             headers: { "Authorization" => "Bearer #{@token}" }
      end
      assert_response :unprocessable_entity
    end

    # Game Start Tests
    test "should start game with minimum players" do
      @game_session.players << @player
      @game_session.players << players(:two)
      @game_session.update(creator_id: @player.id)

      post start_api_game_session_url(@game_session),
           params: { player_id: @player.id },
           headers: { "Authorization" => "Bearer #{@token}" }
      
      assert_response :success
      assert_equal "active", @game_session.reload.status
    end

    test "should not start game with too few players" do
      @game_session.players << @player
      @game_session.update(creator_id: @player.id)

      post start_api_game_session_url(@game_session),
           params: { player_id: @player.id },
           headers: { "Authorization" => "Bearer #{@token}" }
      
      assert_response :unprocessable_entity
      assert_equal "waiting", @game_session.reload.status
    end

    test "should not start game with too many players" do
      @game_session.players << @player
      @game_session.players << players(:two)
      @game_session.players << players(:three)
      @game_session.players << players(:four)
      @game_session.players << players(:five)
      @game_session.update(creator_id: @player.id)

      post start_api_game_session_url(@game_session),
           params: { player_id: @player.id },
           headers: { "Authorization" => "Bearer #{@token}" }
      
      assert_response :unprocessable_entity
      assert_equal "waiting", @game_session.reload.status
    end

    private

    def generate_jwt_token(user)
      JWT.encode(
        { sub: user.id, exp: 24.hours.from_now.to_i },
        Rails.application.credentials.secret_key_base
      )
    end
  end
end 
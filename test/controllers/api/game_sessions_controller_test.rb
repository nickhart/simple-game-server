require "test_helper"

module Api
  class GameSessionsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:one)
      @player = players(:one)
      @waiting_game = game_sessions(:waiting)
      @active_game = game_sessions(:active)
      @finished_game = game_sessions(:finished)
      @token = generate_jwt_token(@user)
      @headers = {
        "Authorization" => "Bearer #{@token}",
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }

      # Set up player associations
      @active_game.players << @player
      @active_game.players << players(:two)
      @active_game.update!(current_player_index: 0)

      @finished_game.players << @player
      @finished_game.players << players(:two)
      @finished_game.update!(current_player_index: 1)
    end

    # Game Session Creation Tests
    test "should create game session" do
      assert_difference("GameSession.count") do
        post "/api/game_sessions/create/#{@player.id}",
             params: {
               game_session: {
                 min_players: 2,
                 max_players: 4
               }
             }.to_json,
             headers: @headers
      end
      assert_response :created
      game_session = GameSession.last
      assert_equal @player.id, game_session.creator_id
    end

    test "should not create game session with invalid player count" do
      assert_no_difference("GameSession.count") do
        post "/api/game_sessions/create/#{@player.id}",
             params: {
               game_session: {
                 min_players: 4,
                 max_players: 2
               }
             }.to_json,
             headers: @headers
      end
      assert_response :unprocessable_entity
    end

    # Game Session Cleanup Tests
    test "should cleanup old waiting games" do
      old_game = GameSession.create!(
        min_players: 2,
        max_players: 4,
        created_at: 2.days.ago,
        status: :waiting,
        creator: @player,
        current_player_index: 0
      )

      post "/api/game_sessions/cleanup",
           params: { before: 1.day.ago.iso8601 }.to_json,
           headers: @headers

      assert_response :success
      assert_not GameSession.exists?(old_game.id)
    end

    test "should not cleanup active games" do
      @active_game.update!(created_at: 2.days.ago)

      post "/api/game_sessions/cleanup",
           params: { before: 1.day.ago.iso8601 }.to_json,
           headers: @headers

      assert_response :success
      assert GameSession.exists?(@active_game.id)
    end

    # Game Session Update Tests
    test "should update game state and advance turn when active" do
      initial_player_index = @active_game.current_player_index

      put api_game_session_path(@active_game),
          params: {
            game_session: {
              state: { board: [1, 0, 0, 0, 0, 0, 0, 0, 0] },
              current_player_index: 0
            }
          }.to_json,
          headers: @headers

      assert_response :success
      @active_game.reload
      assert_equal [1, 0, 0, 0, 0, 0, 0, 0, 0], @active_game.state["board"]
      assert_not_equal initial_player_index, @active_game.current_player_index
    end

    test "should not advance turn when game is finished" do
      initial_player_index = @finished_game.current_player_index

      put api_game_session_path(@finished_game),
          params: {
            game_session: {
              state: { board: [1, 0, 0, 0, 0, 0, 0, 0, 0] },
              current_player_index: 1
            }
          }.to_json,
          headers: @headers

      assert_response :success
      @finished_game.reload
      assert_equal initial_player_index, @finished_game.current_player_index
    end

    # Game Session State Validation Tests
    test "should maintain state between updates" do
      initial_state = { board: [1, 0, 0, 0, 0, 0, 0, 0, 0], current_player: 1 }
      @active_game.state = initial_state
      @active_game.save!

      get api_game_session_path(@active_game),
          headers: @headers

      assert_response :success
      response_state = response.parsed_body["state"]
      assert_equal initial_state["board"], response_state["board"]
      assert_equal initial_state["current_player"], response_state["current_player"]
    end

    # Player Management Tests
    test "should join waiting game" do
      assert_difference("@waiting_game.players.count") do
        post "/api/game_sessions/#{@waiting_game.id}/join/#{@player.id}",
             headers: @headers
      end
      assert_response :success
    end

    test "should not join active game" do
      assert_no_difference("@active_game.players.count") do
        post "/api/game_sessions/#{@active_game.id}/join/#{@player.id}",
             headers: @headers
      end
      assert_response :unprocessable_entity
    end

    test "should not join full game" do
      @waiting_game.players << players(:two)
      @waiting_game.players << players(:three)
      @waiting_game.players << players(:four)
      @waiting_game.update!(max_players: 3)

      assert_no_difference("@waiting_game.players.count") do
        post "/api/game_sessions/#{@waiting_game.id}/join/#{@player.id}",
             headers: @headers
      end
      assert_response :unprocessable_entity
    end

    # Game Start Tests
    test "should start game with minimum players" do
      @waiting_game.players << @player
      @waiting_game.players << players(:two)
      @waiting_game.update!(creator_id: @player.id, min_players: 2, max_players: 4)

      post "/api/game_sessions/#{@waiting_game.id}/start",
           headers: @headers

      assert_response :success
      assert_equal :active, @waiting_game.reload.status
    end

    test "should not start game with too few players" do
      @waiting_game.players << @player
      @waiting_game.update!(creator_id: @player.id, min_players: 2, max_players: 4)

      post "/api/game_sessions/#{@waiting_game.id}/start",
           headers: @headers

      assert_response :unprocessable_entity
      assert_equal :waiting, @waiting_game.reload.status
    end

    test "should not start game with too many players" do
      @waiting_game.players << @player
      @waiting_game.players << players(:two)
      @waiting_game.players << players(:three)
      @waiting_game.players << players(:four)
      @waiting_game.players << players(:five)
      @waiting_game.update!(creator_id: @player.id, min_players: 2, max_players: 4)

      post "/api/game_sessions/#{@waiting_game.id}/start",
           headers: @headers

      assert_response :unprocessable_entity
      assert_equal :waiting, @waiting_game.reload.status
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

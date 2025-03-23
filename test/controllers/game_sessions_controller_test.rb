require "test_helper"

class GameSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game = GameSession.create!(min_players: 2, max_players: 4)
  end

  test "should get index" do
    get game_sessions_url
    assert_response :success
  end

  test "should get new" do
    get new_game_session_url
    assert_response :success
  end

  test "should create game_session" do
    assert_difference("GameSession.count") do
      post game_sessions_url, params: {
        game_session: { min_players: 2, max_players: 4 }
      }
    end

    assert_redirected_to game_session_url(GameSession.last)
  end

  test "should show game_session" do
    get game_session_url(@game)
    assert_response :success
  end

  test "should not create invalid game_session" do
    assert_no_difference("GameSession.count") do
      post game_sessions_url, params: {
        game_session: { min_players: 4, max_players: 2 }
      }
    end

    assert_response :unprocessable_entity
  end
end

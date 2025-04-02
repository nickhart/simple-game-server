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

  test "should handle missing game session gracefully" do
    get game_session_url(id: 99_999)
    assert_redirected_to game_sessions_path
    assert_equal "Game session not found.", flash[:alert]
  end

  test "should handle database errors in index" do
    GameSession.class_eval do
      def self.all
        raise ActiveRecord::StatementInvalid, "Test error"
      end
    end

    get game_sessions_url
    assert_response :success
    assert_equal [], assigns(:game_sessions)
  ensure
    GameSession.singleton_class.remove_method(:all)
  end

  test "should handle errors in create" do
    GameSession.class_eval do
      def save
        raise StandardError, "Test error"
      end
    end

    post game_sessions_url, params: {
      game_session: { min_players: 2, max_players: 4 }
    }
    assert_response :unprocessable_entity
    assert_equal "Error creating game session. Please try again.", flash[:alert]
  ensure
    GameSession.class_eval do
      remove_method :save
    end
  end

  test "should handle invalid parameters in create" do
    post game_sessions_url, params: {
      game_session: { min_players: "invalid", max_players: "invalid" }
    }
    assert_response :unprocessable_entity
  end

  test "should handle missing parameters in create" do
    post game_sessions_url, params: {}
    assert_response :unprocessable_entity
    assert_match(/param is missing or the value is empty/, flash[:alert])
  end
end

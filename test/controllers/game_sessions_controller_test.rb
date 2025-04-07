require "test_helper"

class GameSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @game = GameSession.create!(min_players: 2, max_players: 4)
  end

  # View Tests
  test "should get index" do
    get game_sessions_url
    assert_response :success
    assert_not_nil assigns(:game_sessions)
  end

  test "should get new" do
    get new_game_session_url
    assert_response :success
    assert_not_nil assigns(:game_session)
  end

  test "should show game_session" do
    get game_session_url(@game)
    assert_response :success
    assert_not_nil assigns(:game_session)
  end

  # Web Form Creation Tests
  test "should create game_session via web form" do
    assert_difference("GameSession.count") do
      post game_sessions_url, params: {
        game_session: { min_players: 2, max_players: 4 }
      }
    end

    assert_redirected_to game_session_url(GameSession.last)
    assert_equal "Game session was successfully created.", flash[:notice]
  end

  test "should not create invalid game_session via web form" do
    assert_no_difference("GameSession.count") do
      post game_sessions_url, params: {
        game_session: { min_players: 4, max_players: 2 }
      }
    end

    assert_response :unprocessable_entity
    assert_template :new
  end

  # Error Handling Tests
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
    assert_equal "Error retrieving game sessions. Please try again.", flash[:alert]
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

  # Form Validation Tests
  test "should handle invalid parameters in create" do
    post game_sessions_url, params: {
      game_session: { min_players: "invalid", max_players: "invalid" }
    }
    assert_response :unprocessable_entity
    assert_template :new
  end

  test "should handle missing parameters in create" do
    post game_sessions_url, params: {}
    assert_response :unprocessable_entity
    assert_match(/param is missing or the value is empty/, flash[:alert])
  end

  # Session Management Tests
  test "should handle session timeout" do
    get game_sessions_url
    assert_response :success

    # Simulate session timeout
    session[:user_id] = nil

    get game_sessions_url
    assert_redirected_to login_path
    assert_equal "Your session has expired. Please log in again.", flash[:alert]
  end

  # Flash Message Tests
  test "should show appropriate flash messages" do
    # Test success message
    post game_sessions_url, params: {
      game_session: { min_players: 2, max_players: 4 }
    }
    assert_equal "Game session was successfully created.", flash[:notice]

    # Test error message
    post game_sessions_url, params: {
      game_session: { min_players: 4, max_players: 2 }
    }
    assert_match(/Min players cannot be greater than max players/, flash[:alert])
  end
end

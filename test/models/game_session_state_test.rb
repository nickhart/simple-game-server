require "test_helper"

class GameSessionStateTest < ActiveSupport::TestCase
  setup do
    @game_session = GameSession.new(
      min_players: 2,
      max_players: 4,
      status: :waiting
    )
    @player1 = Player.create!(name: "Player 1")
    @player2 = Player.create!(name: "Player 2")
  end

  test "should not allow invalid state transitions" do
    @game_session.status = :finished
    assert_not @game_session.save, "Should not save game session with invalid initial state"

    @game_session.status = :waiting
    assert @game_session.save, "Should save game session with valid initial state"

    @game_session.status = :finished
    assert_not @game_session.save, "Should not allow transition from waiting to finished"

    # Test transition from active to waiting
    @game_session.game_players.create!(player: @player1)
    @game_session.game_players.create!(player: @player2)
    @game_session.status = :active
    assert @game_session.save, "Should transition to active"

    @game_session.status = :waiting
    assert_not @game_session.save, "Should not allow transition from active back to waiting"
  end

  test "should handle state transitions correctly" do
    assert @game_session.save
    @game_session.game_players.create!(player: @player1)
    @game_session.game_players.create!(player: @player2)

    @game_session.status = :active
    assert @game_session.save, "Should allow transition to active with enough players"

    @game_session.status = :finished
    assert @game_session.save, "Should allow transition from active to finished"

    @game_session.status = :active
    assert_not @game_session.save, "Should not allow transition from finished back to active"
  end

  test "should enforce player count constraints during state transitions" do
    assert @game_session.save
    @game_session.game_players.create!(player: @player1)

    @game_session.status = :active
    assert_not @game_session.save, "Should not allow transition to active with insufficient players"

    @game_session.game_players.create!(player: @player2)
    @game_session.status = :active
    assert @game_session.save, "Should allow transition to active with minimum required players"
  end

  test "should handle game completion through finish_game method" do
    assert @game_session.save
    @game_session.game_players.create!(player: @player1)
    @game_session.game_players.create!(player: @player2)

    assert @game_session.start_game, "Should start game successfully"
    assert @game_session.status_active?, "Game should be active after starting"

    assert @game_session.finish_game, "Should finish game successfully"
    assert @game_session.status_finished?, "Game should be finished after calling finish_game"
  end

  test "should handle edge cases in state transitions" do
    # Test nil status_was case
    new_game = GameSession.new(min_players: 2, max_players: 4)
    new_game.status = :waiting
    assert new_game.valid?, "Should allow setting initial status"

    # Test setting status to nil
    @game_session.write_attribute(:status, nil)
    assert_not @game_session.valid?, "Should not allow nil status"
    assert_includes @game_session.errors[:status], "can't be blank"

    # Test setting status to invalid value
    assert_raises(ArgumentError) do
      @game_session.status = :invalid_status
    end
  end

  test "should handle current_player_index initialization" do
    assert @game_session.save
    @game_session.game_players.create!(player: @player1)
    @game_session.game_players.create!(player: @player2)

    assert_nil @game_session.current_player_index, "Should start with nil current_player_index"
    @game_session.status = :active
    assert @game_session.save, "Should transition to active"
    assert_equal 0, @game_session.current_player_index, "Should initialize current_player_index to 0"
  end
end

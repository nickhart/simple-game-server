require "test_helper"

class GameSessionTest < ActiveSupport::TestCase
  def setup
    @game = GameSession.new(min_players: 2, max_players: 4)
    @player1 = Player.create!(name: "Player 1")
    @player2 = Player.create!(name: "Player 2")
    @player3 = Player.create!(name: "Player 3")
  end

  # Basic Validation Tests
  test "should be valid with valid attributes" do
    assert @game.valid?
  end

  test "should not be valid without min_players" do
    @game.min_players = nil
    assert_not @game.valid?
  end

  test "should not be valid without max_players" do
    @game.max_players = nil
    assert_not @game.valid?
  end

  test "should not allow min_players less than 1" do
    @game.min_players = 0
    assert_not @game.valid?
  end

  test "should not allow max_players less than min_players" do
    @game.min_players = 3
    @game.max_players = 2
    assert_not @game.valid?
  end

  test "should allow equal min and max players" do
    game = GameSession.new(min_players: 2, max_players: 2)
    assert game.valid?
  end

  # Game State Management Tests
  test "should start with waiting status" do
    @game.save!
    assert_equal :waiting, @game.status
  end

  test "should transition to active when started" do
    @game.save!
    @game.add_player(@player1)
    @game.add_player(@player2)
    @game.start_game
    assert_equal :active, @game.status
  end

  test "should transition to finished when game ends" do
    @game.save!
    @game.add_player(@player1)
    @game.add_player(@player2)
    @game.start_game
    @game.finish_game
    assert_equal :finished, @game.status
  end

  # Player Management Tests
  test "should add player successfully" do
    @game.save!
    assert @game.add_player(@player1)
    assert_equal 1, @game.players.count
  end

  test "should not add player if game is active" do
    @game.save!
    @game.add_player(@player1)
    @game.add_player(@player2)
    @game.start_game
    assert_not @game.add_player(@player3)
  end

  test "should not add player if game is finished" do
    @game.save!
    @game.add_player(@player1)
    @game.add_player(@player2)
    @game.start_game
    @game.finish_game
    assert_not @game.add_player(@player3)
  end

  test "should not add player if game is full" do
    game = GameSession.create!(min_players: 2, max_players: 2)
    game.add_player(@player1)
    game.add_player(@player2)
    assert_not game.add_player(@player3)
  end

  # Game Start Tests
  test "should start game with minimum players" do
    @game.save!
    @game.add_player(@player1)
    @game.add_player(@player2)
    assert @game.start_game
    assert_equal :active, @game.status
  end

  test "should not start game with insufficient players" do
    @game.save!
    @game.add_player(@player1)
    assert_not @game.start_game
    assert_equal :waiting, @game.status
  end

  test "should not start game with too many players" do
    game = GameSession.create!(min_players: 2, max_players: 2)
    game.add_player(@player1)
    game.add_player(@player2)
    game.add_player(@player3)
    assert_not game.start_game
    assert_equal :waiting, game.status
  end

  # Turn Management Tests
  test "should advance turn correctly" do
    @game.save!
    @game.add_player(@player1)
    @game.add_player(@player2)
    @game.start_game

    initial_player = @game.current_player
    @game.advance_turn
    next_player = @game.current_player

    assert_not_equal initial_player, next_player
  end

  test "should cycle through all players" do
    @game.save!
    @game.add_player(@player1)
    @game.add_player(@player2)
    @game.start_game

    first_player = @game.current_player
    @game.advance_turn
    @game.advance_turn

    assert_equal first_player, @game.current_player
  end

  test "should not advance turn if game is not active" do
    @game.save!
    @game.add_player(@player1)
    @game.add_player(@player2)

    initial_player = @game.current_player
    @game.advance_turn

    assert_equal initial_player, @game.current_player
  end

  # State Update Tests
  test "should handle state updates correctly" do
    @game.save!
    @game.add_player(@player1)
    @game.add_player(@player2)
    @game.start_game

    new_state = { board: [1, 0, 0, 0, 0, 0, 0, 0, 0] }
    @game.state = new_state
    @game.save!

    assert_equal new_state, @game.reload.state
  end

  test "should merge state updates" do
    @game.save!
    @game.add_player(@player1)
    @game.add_player(@player2)
    @game.start_game

    initial_state = { board: [1, 0, 0, 0, 0, 0, 0, 0, 0], current_player: 1 }
    @game.state = initial_state
    @game.save!

    update_state = { board: [1, 2, 0, 0, 0, 0, 0, 0, 0] }
    @game.state = @game.state.merge(update_state)
    @game.save!

    expected_state = { board: [1, 2, 0, 0, 0, 0, 0, 0, 0], current_player: 1 }
    assert_equal expected_state, @game.reload.state
  end

  # Game Completion Tests
  test "should handle game completion with winner" do
    @game.save!
    @game.add_player(@player1)
    @game.add_player(@player2)
    @game.start_game

    @game.state = { board: [1, 1, 1, 2, 2, 0, 0, 0, 0], winner: 0 }
    @game.status = :finished
    @game.save!

    assert_equal :finished, @game.status
    assert_equal 0, @game.state["winner"]
  end

  test "should handle game completion with draw" do
    @game.save!
    @game.add_player(@player1)
    @game.add_player(@player2)
    @game.start_game

    @game.state = { board: [1, 2, 1, 1, 2, 2, 2, 1, 1] }
    @game.status = :finished
    @game.save!

    assert_equal :finished, @game.status
    assert_nil @game.state["winner"]
  end

  # Game Session Cleanup Tests
  test "should be eligible for cleanup if waiting and old" do
    game = GameSession.create!(
      min_players: 2,
      max_players: 4,
      created_at: 2.days.ago,
      status: :waiting
    )
    assert game.eligible_for_cleanup?
  end

  test "should not be eligible for cleanup if active" do
    game = GameSession.create!(
      min_players: 2,
      max_players: 4,
      created_at: 2.days.ago,
      status: :active
    )
    game.players << @player1
    assert_not game.eligible_for_cleanup?
  end

  test "should not be eligible for cleanup if recent" do
    game = GameSession.create!(
      min_players: 2,
      max_players: 4,
      created_at: 1.hour.ago,
      status: :waiting
    )
    assert_not game.eligible_for_cleanup?
  end
end

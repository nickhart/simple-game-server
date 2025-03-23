require "test_helper"

class GameSessionTest < ActiveSupport::TestCase
  def setup
    @game = GameSession.new(min_players: 2, max_players: 4)
    @player1 = Player.create!(name: "Player 1")
    @player2 = Player.create!(name: "Player 2")
    @player3 = Player.create!(name: "Player 3")
  end

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

  test "should start with waiting status" do
    @game.save!
    assert_equal "waiting", @game.status
  end

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

  test "should not add player if game is full" do
    game = GameSession.create!(min_players: 2, max_players: 2)
    game.add_player(@player1)
    game.add_player(@player2)
    assert_not game.add_player(@player3)
  end

  test "should start game with minimum players" do
    @game.save!
    @game.add_player(@player1)
    @game.add_player(@player2)
    assert @game.start_game
    assert_equal "active", @game.status
  end

  test "should not start game with insufficient players" do
    @game.save!
    @game.add_player(@player1)
    assert_not @game.start_game
    assert_equal "waiting", @game.status
  end

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
end

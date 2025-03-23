require "test_helper"

class GamePlayerTest < ActiveSupport::TestCase
  def setup
    @game = GameSession.create!(min_players: 2, max_players: 4)
    @player = Player.create!(name: "Test Player")
    @game_player = GamePlayer.new(game_session: @game, player: @player)
  end

  test "should be valid with valid attributes" do
    assert @game_player.valid?
  end

  test "should not be valid without game_session" do
    @game_player.game_session = nil
    assert_not @game_player.valid?
  end

  test "should not be valid without player" do
    @game_player.player = nil
    assert_not @game_player.valid?
  end

  test "should not allow duplicate player in same game" do
    @game_player.save!
    duplicate = GamePlayer.new(game_session: @game, player: @player)
    assert_not duplicate.valid?
  end

  test "should allow same player in different games" do
    @game_player.save!
    other_game = GameSession.create!(min_players: 2, max_players: 4)
    other_game_player = GamePlayer.new(game_session: other_game, player: @player)
    assert other_game_player.valid?
  end
end

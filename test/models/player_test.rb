require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  def setup
    @player = Player.new(name: "Test Player")
  end

  test "should be valid with valid attributes" do
    assert @player.valid?
  end

  test "should not be valid without name" do
    @player.name = nil
    assert_not @player.valid?
  end

  test "should be able to join multiple games" do
    @player.save!
    game1 = GameSession.create!(min_players: 2, max_players: 4)
    game2 = GameSession.create!(min_players: 2, max_players: 4)

    game1.add_player(@player)
    game2.add_player(@player)

    assert_equal 2, @player.game_sessions.count
  end

  test "should be removed from games when destroyed" do
    @player.save!
    game = GameSession.create!(min_players: 2, max_players: 4)
    game.add_player(@player)

    assert_difference 'GamePlayer.count', -1 do
      @player.destroy
    end
  end
end

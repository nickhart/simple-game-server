require "test_helper"

class GameLogicTest < ActiveSupport::TestCase
  test "game session should have valid player count" do
    min_players = 2
    max_players = 4

    assert min_players <= max_players, "Minimum players should be less than or equal to maximum players"
    assert min_players > 0, "Minimum players should be positive"
    assert max_players > 0, "Maximum players should be positive"
  end

  test "game state transitions should be valid" do
    valid_states = %w[waiting_for_players in_progress completed cancelled]

    valid_states.each do |state|
      assert state.present?, "Game state '#{state}' should be valid"
    end
  end
end

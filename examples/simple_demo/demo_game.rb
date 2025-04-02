#!/usr/bin/env rails runner

# Create three players
puts "Creating players..."
player1 = Player.create!(name: "Alice")
player2 = Player.create!(name: "Bob")
player3 = Player.create!(name: "Charlie")
puts "Created players: #{player1.name}, #{player2.name}, #{player3.name}"

# Create a game session for exactly 3 players
puts "\nCreating game session..."
game = GameSession.create!(min_players: 3, max_players: 3)
puts "Created game session ##{game.id} (Status: #{game.status})"

# Add all three players
puts "\nAdding players to game..."
game.add_player(player1)
game.add_player(player2)
game.add_player(player3)
puts "Added #{game.players.count} players to the game"

# Start the game
puts "\nStarting game..."
if game.start_game
  puts "Game started successfully! (Status: #{game.status})"
else
  puts "Failed to start game: #{game.errors.full_messages.join(', ')}"
  exit 1
end

# Simulate 6 turns (2 full rotations)
puts "\nSimulating turns..."
6.times do |i|
  current = game.current_player
  puts "Turn #{i + 1}: #{current.name}'s turn"
  game.advance_turn
end

# End the game
puts "\nEnding game..."
game.update!(status: :finished)
puts "Game finished! (Status: #{game.status})"

# Final game state
puts "\nFinal game state:"
puts "Game ID: #{game.id}"
puts "Status: #{game.status}"
puts "Players: #{game.players.pluck(:name).join(', ')}"

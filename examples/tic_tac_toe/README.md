# Tic Tac Toe Example Client

This is a simple command-line client that demonstrates how to use the Simple Game Server API to play a game of Tic Tac Toe.

## Features

- Interactive command-line interface
- Full game flow demonstration:
  - Create game sessions
  - Join as players
  - Start games
  - Make moves
  - Display the game board
  - Handle game completion

## Requirements

- Ruby 2.7 or higher
- Access to a running Simple Game Server instance

## Setup

1. Make sure the Simple Game Server is running locally on port 3000
2. Run the game:
   ```bash
   ruby game.rb
   ```

## Usage

1. When prompted, enter your email and password to authenticate
2. Create a new game or join an existing one
3. Wait for other players to join
4. Start the game when ready
5. Take turns making moves by entering the position (1-9)
6. The game ends when someone wins or the board is full

## File Structure

- `game.rb` - Main game script with the interactive interface
- `board.rb` - Board display and game logic
- `client.rb` - API client for communicating with the server 
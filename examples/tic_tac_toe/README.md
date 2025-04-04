# Tic Tac Toe Example

A command-line implementation of Tic Tac Toe that demonstrates how to use the Simple Game Server API. This example shows how to:
- Create and join game sessions
- Manage game state
- Handle turn-based gameplay
- Communicate with the game server

## Requirements

- Ruby 3.2.2 or later
- Access to a running Simple Game Server instance
- Valid player credentials (email and password)

## Installation

1. Navigate to the example directory:
```bash
cd examples/tic_tac_toe
```

2. Install dependencies:
```bash
bundle install
```

## Usage

### Command Line Arguments

```bash
ruby game.rb [options]
```

#### Options:
- `--server-url URL`: URL of the game server (default: http://localhost:3000)
- `--email EMAIL`: Player email for authentication
- `--password PASSWORD`: Player password for authentication
- `--create`: Create a new game session
- `--join SESSION_ID`: Join an existing game session
- `--help`: Show help message

### Creating a New Game

1. Start the game as the first player (creator):
```bash
ruby game.rb --server-url http://localhost:3000 --email player1@example.com --password password123 --create
```

2. The game will display a session ID. Share this ID with the second player.

### Joining a Game

1. Start the game as the second player:
```bash
ruby game.rb --server-url http://localhost:3000 --email player2@example.com --password password123 --join SESSION_ID
```

Replace `SESSION_ID` with the ID provided by the first player.

### Gameplay

1. The creator starts the game by pressing Enter when both players have joined.
2. Players take turns making moves by entering a number (1-9) corresponding to the board position:
```
 1 | 2 | 3
-----------
 4 | 5 | 6
-----------
 7 | 8 | 9
```
3. The game continues until:
   - A player wins by getting three in a row
   - The board is full (draw)
   - A player leaves the game

## Implementation Details

### Game State
The game state is stored as a JSON object with the following structure:
```json
{
  "board": [0, 0, 0, 0, 0, 0, 0, 0, 0],
  "current_player": 1,
  "winner": null
}
```
Where:
- `board`: Array representing the game board (0 = empty, 1 = X, 2 = O)
- `current_player`: Index of the current player (0 or 1)
- `winner`: Index of the winning player (null if game is not finished)

### Client-Server Communication

The client communicates with the server using the following endpoints:
- `POST /api/game_sessions`: Create a new game session
- `POST /api/game_sessions/:id/join`: Join an existing game session
- `POST /api/game_sessions/:id/start`: Start the game
- `PUT /api/game_sessions/:id`: Update game state
- `GET /api/game_sessions/:id`: Get current game state
- `DELETE /api/game_sessions/:id/leave`: Leave the game

## Future Enhancements

### Short Term
- Add player registration support
- Implement game session cleanup/removal
- Add error handling for network issues
- Improve game state validation

### Medium Term
- Add support for reconnecting to games
- Implement game session persistence
- Add support for multiple game types
- Improve error messages and user feedback

### Long Term
- Add support for custom game boards
- Implement game statistics and history
- Add support for tournaments
- Create a web-based UI version

## Contributing

Feel free to submit issues and enhancement requests. If you'd like to contribute:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

This example is part of the Simple Game Server project and is licensed under the MIT License. 
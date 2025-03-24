# SimpleGameServer API Documentation

## Overview
SimpleGameServer is a RESTful API that manages game sessions for various game types. Currently, it supports TicTacToe games with two players.

## Base URL
```
http://localhost:3000
```

## Authentication
Currently, the API does not require authentication.

## Endpoints

### Game Sessions

#### List Game Sessions
```http
GET /game_sessions
```

**Response**
```json
{
  "game_sessions": [
    {
      "id": 1,
      "status": "waiting",
      "min_players": 2,
      "max_players": 2,
      "current_player_index": 0,
      "game_type": "tictactoe",
      "players": [
        {
          "id": 1,
          "name": "Player 1"
        }
      ],
      "board": ["", "", "", "", "", "", "", "", ""],
      "winner": null
    }
  ]
}
```

#### Create Game Session
```http
POST /game_sessions
```

**Request Body**
```json
{
  "game_type": "tictactoe"
}
```

**Response**
```json
{
  "id": 1,
  "status": "waiting",
  "min_players": 2,
  "max_players": 2,
  "current_player_index": 0,
  "game_type": "tictactoe",
  "players": [],
  "board": ["", "", "", "", "", "", "", "", ""],
  "winner": null
}
```

#### Join Game Session
```http
POST /game_sessions/:id/join
```

**Request Body**
```json
{
  "player_name": "Player 1"
}
```

**Response**
```json
{
  "id": 1,
  "status": "waiting",
  "min_players": 2,
  "max_players": 2,
  "current_player_index": 0,
  "game_type": "tictactoe",
  "players": [
    {
      "id": 1,
      "name": "Player 1"
    }
  ],
  "board": ["", "", "", "", "", "", "", "", ""],
  "winner": null
}
```

#### Make Move
```http
POST /game_sessions/:id/move
```

**Request Body**
```json
{
  "player_id": 1,
  "position": 0
}
```

**Response**
```json
{
  "id": 1,
  "status": "active",
  "min_players": 2,
  "max_players": 2,
  "current_player_index": 1,
  "game_type": "tictactoe",
  "players": [
    {
      "id": 1,
      "name": "Player 1"
    },
    {
      "id": 2,
      "name": "Player 2"
    }
  ],
  "board": ["X", "", "", "", "", "", "", "", ""],
  "winner": null
}
```

## Game Rules

### TicTacToe
- The game is played on a 3x3 grid
- Players take turns placing their marks (X or O) in empty squares
- The first player to get 3 of their marks in a row (horizontally, vertically, or diagonally) wins
- If all squares are filled and no player has won, the game is a draw

### Board Positions
The board is represented as a 9-element array where positions are mapped as follows:
```
0 | 1 | 2
---------
3 | 4 | 5
---------
6 | 7 | 8
```

## Status Codes
- `200 OK`: Request successful
- `400 Bad Request`: Invalid request parameters
- `404 Not Found`: Resource not found
- `422 Unprocessable Entity`: Validation error
- `500 Internal Server Error`: Server error

## Error Response Format
```json
{
  "error": "Error message description"
}
```

## Game Session States
1. `waiting`: Initial state, waiting for players to join
2. `active`: Game is in progress
3. `finished`: Game has ended (either won or drawn)

## Implementation Notes
- Game sessions are stored in memory and will be lost when the server restarts
- Player IDs are assigned sequentially starting from 1
- The first player to join uses X, the second player uses O
- The game automatically starts when the minimum number of players (2) joins
- The game ends when there's a winner or a draw

## Example Game Flow
1. Create a new game session
2. First player joins and gets player_id 1
3. Second player joins and gets player_id 2
4. Players take turns making moves using their player_id
5. Game continues until there's a winner or a draw

## TypeScript Types
```typescript
interface Player {
  id: number;
  name: string;
}

interface GameSession {
  id: number;
  status: 'waiting' | 'active' | 'finished';
  min_players: number;
  max_players: number;
  current_player_index: number;
  game_type: 'tictactoe';
  players: Player[];
  board: string[];
  winner: number | null;
}

interface CreateGameSessionRequest {
  game_type: 'tictactoe';
}

interface JoinGameSessionRequest {
  player_name: string;
}

interface MakeMoveRequest {
  player_id: number;
  position: number;
}
``` 
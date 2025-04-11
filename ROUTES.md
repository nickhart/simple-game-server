# Simple Game Server - Route Documentation

## Base URL
```
http://localhost:3000
```

## Authentication
Currently, the API does not require authentication.

## Game Session Routes

### 1. List Game Sessions
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

**Description**
Returns a list of all available game sessions, including their current state and players.

### 2. Create Game Session
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

**Description**
Creates a new game session of the specified type. Currently only supports "tictactoe" as the game type.

### 3. Join Game Session
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

**Description**
Allows a player to join an existing game session. The game will start automatically when the minimum number of players (2 for Tic Tac Toe) has joined.

### 4. Make Move
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

**Description**
Allows a player to make a move in the game. The position parameter represents the board position (0-8) where the move should be made.

### 5. Cleanup Unused Game Sessions
```http
POST /game_sessions/cleanup
```

**Request Body**
```json
{
  "before": "2024-03-26T00:00:00Z"
}
```

**Response**
```json
{
  "message": "Deleted 5 unused game sessions created before 2024-03-26T00:00:00Z",
  "deleted_count": 5
}
```

**Description**
Deletes all game sessions that:
- Were created before the specified date
- Have no players (haven't been joined)
- Are in 'waiting' status

## Response Status Codes

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

## Board Position Mapping
The board is represented as a 9-element array where positions are mapped as follows:
```
0 | 1 | 2
---------
3 | 4 | 5
---------
6 | 7 | 8
```

## TypeScript Types for API Responses

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

interface CleanupRequest {
  before: string; // ISO 8601 date string
}
```

## Implementation Notes
- Game sessions are stored in memory and will be lost when the server restarts
- Player IDs are assigned sequentially starting from 1
- The first player to join uses X, the second player uses O
- The game automatically starts when the minimum number of players (2) joins
- The game ends when there's a winner or a draw 
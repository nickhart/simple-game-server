# Simple Game Server - API Documentation

## Base URL
```
http://localhost:3000
```

---

# Authentication Routes

### 1. User Registration
```http
POST /auth/register
```

**Request Body**
```json
{
  "username": "user123",
  "password": "securePassword"
}
```

**Response**
```json
{
  "id": 1,
  "username": "user123",
  "created_at": "2024-06-01T12:00:00Z"
}
```

**Description**  
Registers a new user account.

---

### 2. User Login
```http
POST /auth/login
```

**Request Body**
```json
{
  "username": "user123",
  "password": "securePassword"
}
```

**Response**
```json
{
  "token": "jwt-token-string",
  "user": {
    "id": 1,
    "username": "user123"
  }
}
```

**Description**  
Authenticates a user and returns a JWT token for authorized requests.

---

# User Routes

### 3. Get Current User Profile
```http
GET /users/me
```

**Response**
```json
{
  "id": 1,
  "username": "user123",
  "created_at": "2024-06-01T12:00:00Z"
}
```

**Description**  
Returns the profile information of the authenticated user.

---

### 4. Update Current User Profile
```http
PATCH /users/me
```

**Request Body**
```json
{
  "username": "newUsername"
}
```

**Response**
```json
{
  "id": 1,
  "username": "newUsername",
  "created_at": "2024-06-01T12:00:00Z"
}
```

**Description**  
Updates the authenticated user's profile information.

---

# Player Routes

### 5. List Players
```http
GET /players
```

**Response**
```json
[
  {
    "id": 1,
    "name": "Player 1",
    "user_id": 1
  },
  {
    "id": 2,
    "name": "Player 2",
    "user_id": 2
  }
]
```

**Description**  
Returns a list of all players.

---

### 6. Create Player
```http
POST /players
```

**Request Body**
```json
{
  "name": "Player 1"
}
```

**Response**
```json
{
  "id": 1,
  "name": "Player 1",
  "user_id": 1
}
```

**Description**  
Creates a new player associated with the authenticated user.

---

### 7. Update Player
```http
PATCH /players/:id
```

**Request Body**
```json
{
  "name": "Updated Player Name"
}
```

**Response**
```json
{
  "id": 1,
  "name": "Updated Player Name",
  "user_id": 1
}
```

**Description**  
Updates the specified player's information.

---

### 8. Delete Player
```http
DELETE /players/:id
```

**Response**
```json
{
  "message": "Player deleted successfully"
}
```

**Description**  
Deletes the specified player.

---

# Game Routes

### 9. List Available Games
```http
GET /games
```

**Response**
```json
[
  {
    "id": 1,
    "name": "Tic Tac Toe",
    "min_players": 2,
    "max_players": 2
  }
]
```

**Description**  
Returns a list of available games.

---

# Game Session Routes

### 10. List Game Sessions
```http
GET /game_sessions
```

**Response**
```json
[
  {
    "id": 1,
    "game_id": 1,
    "status": "waiting",
    "min_players": 2,
    "max_players": 2,
    "current_player_index": 0,
    "players": [
      {
        "id": 1,
        "name": "Player 1"
      }
    ],
    "board": ["", "", "", "", "", "", "", "", ""],
    "winner": null,
    "created_at": "2024-06-01T12:00:00Z"
  }
]
```

**Description**  
Returns all game sessions with their current state and players.

---

### 11. Create Game Session
```http
POST /game_sessions
```

**Request Body**
```json
{
  "game_id": 1
}
```

**Response**
```json
{
  "id": 1,
  "game_id": 1,
  "status": "waiting",
  "min_players": 2,
  "max_players": 2,
  "current_player_index": 0,
  "players": [],
  "board": ["", "", "", "", "", "", "", "", ""],
  "winner": null,
  "created_at": "2024-06-01T12:00:00Z"
}
```

**Description**  
Creates a new game session for a specified game.

---

### 12. Join Game Session
```http
POST /game_sessions/:id/join
```

**Request Body**
```json
{
  "player_id": 1
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
  "players": [
    {
      "id": 1,
      "name": "Player 1"
    }
  ],
  "board": ["", "", "", "", "", "", "", "", ""],
  "winner": null,
  "created_at": "2024-06-01T12:00:00Z"
}
```

**Description**  
Allows a player to join an existing game session. The game starts automatically when minimum players join.

---

### 13. Make Move
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
  "winner": null,
  "created_at": "2024-06-01T12:00:00Z"
}
```

**Description**  
Allows a player to make a move in the game. Position is the board index (0-8).

---

### 14. Update Game Session (e.g., for status updates)
```http
PATCH /game_sessions/:id
```

**Request Body**
```json
{
  "status": "finished",
  "winner": 1
}
```

**Response**
```json
{
  "id": 1,
  "status": "finished",
  "min_players": 2,
  "max_players": 2,
  "current_player_index": 1,
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
  "board": ["X", "O", "X", "O", "X", "O", "O", "X", "X"],
  "winner": 1,
  "created_at": "2024-06-01T12:00:00Z"
}
```

**Description**  
Updates game session properties such as status or winner.

---

### 15. Delete Game Session
```http
DELETE /game_sessions/:id
```

**Response**
```json
{
  "message": "Game session deleted successfully"
}
```

**Description**  
Deletes a specified game session.

---

### 16. Cleanup Unused Game Sessions
```http
POST /game_sessions/cleanup
```

**Request Body**
```json
{
  "before": "2024-06-01T00:00:00Z"
}
```

**Response**
```json
{
  "message": "Deleted 3 unused game sessions created before 2024-06-01T00:00:00Z",
  "deleted_count": 3
}
```

**Description**  
Deletes game sessions that are in 'waiting' status, have no players, and were created before the specified date.

---

# HTTP Status Codes Summary

- `200 OK`: Request succeeded.
- `201 Created`: Resource created successfully.
- `204 No Content`: Resource deleted successfully.
- `400 Bad Request`: Invalid request parameters or malformed request.
- `401 Unauthorized`: Authentication required or failed.
- `403 Forbidden`: Insufficient permissions.
- `404 Not Found`: Resource not found.
- `422 Unprocessable Entity`: Validation errors.
- `500 Internal Server Error`: Server error.

---

# Error Response Format

```json
{
  "error": "Error message describing what went wrong"
}
```

---

# TypeScript Interfaces

```typescript
// Authentication
interface RegisterRequest {
  username: string;
  password: string;
}

interface LoginRequest {
  username: string;
  password: string;
}

interface LoginResponse {
  token: string;
  user: User;
}

// User
interface User {
  id: number;
  username: string;
  created_at: string; // ISO 8601 date string
}

interface UpdateUserRequest {
  username?: string;
}

// Player
interface Player {
  id: number;
  name: string;
  user_id: number;
}

interface CreatePlayerRequest {
  name: string;
}

interface UpdatePlayerRequest {
  name?: string;
}

// Game
interface Game {
  id: number;
  name: string;
  min_players: number;
  max_players: number;
}

// Game Session
type GameSessionStatus = 'waiting' | 'active' | 'finished';

interface GameSession {
  id: number;
  game_id: number;
  status: GameSessionStatus;
  min_players: number;
  max_players: number;
  current_player_index: number;
  players: Player[];
  board: string[]; // e.g., ["", "X", "O", ...]
  winner: number | null; // player id or null
  created_at: string; // ISO 8601 date string
}

interface CreateGameSessionRequest {
  game_id: number;
}

interface JoinGameSessionRequest {
  player_id: number;
}

interface MakeMoveRequest {
  player_id: number;
  position: number; // 0-8 board index
}

interface UpdateGameSessionRequest {
  status?: GameSessionStatus;
  winner?: number | null;
}

interface CleanupRequest {
  before: string; // ISO 8601 date string
}
```

---

# Notes

- All endpoints requiring authentication expect a Bearer token in the `Authorization` header.
- Player IDs are linked to user accounts.
- Game-specific logic, such as board layouts and turn sequencing, is defined per game and not part of this shared API documentation.
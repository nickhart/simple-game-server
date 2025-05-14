# Simple Game Server - API Documentation

## Base URL
```
http://localhost:3000
```

## Table of Contents

### Authentication Routes
- [User Registration](#1-user-registration)
- [User Login](#2-user-login)
- [Refresh Token](#3-refresh-token)
- [Logout](#4-logout)

### User Routes
- [Get Current User Profile](#5-get-current-user-profile)
- [Get User](#6-get-user)
- [Update User](#7-update-user)

### Player Routes
- [Get Current Player](#8-get-current-player)
- [Create Player](#9-create-player)
- [Get Player](#10-get-player)

### Game Routes
- [List Games](#11-list-games)
- [Get Game](#12-get-game)

### Game Session Routes
- [List Game Sessions](#13-list-game-sessions)
- [Create Game Session](#14-create-game-session)
- [Get Game Session](#15-get-game-session)
- [Update Game Session](#16-update-game-session)
- [Join Game Session](#17-join-game-session)
- [Start Game Session](#18-start-game-session)
- [Leave Game Session](#19-leave-game-session)

### Admin Routes
- [List Users](#20-list-users-admin)
- [Create User](#21-create-user-admin)
- [Get User](#22-get-user-admin)
- [Update User](#23-update-user-admin)
- [Make User Admin](#24-make-user-admin)
- [Remove User Admin](#25-remove-user-admin)
- [Create Game](#26-create-game-admin)
- [Update Game](#27-update-game-admin)
- [Delete Game](#28-delete-game-admin)
- [Update Game Schema](#29-update-game-schema-admin)
- [Cleanup Game Sessions](#30-cleanup-game-sessions-admin)
- [Delete Game Session](#31-delete-game-session-admin)

### Additional Information
- [HTTP Status Codes Summary](#http-status-codes-summary)
- [Error Response Format](#error-response-format)
- [TypeScript Interfaces](#typescript-interfaces)
- [Notes](#notes)

---

# Authentication Routes

### 1. User Registration
```http
POST /api/users
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
POST /api/tokens/login
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

### 3. Refresh Token
```http
POST /api/tokens/refresh
```

**Response**
```json
{
  "token": "new-jwt-token-string"
}
```

**Description**  
Refreshes the current JWT token.

---

### 4. Logout
```http
DELETE /api/tokens/logout
```

**Description**  
Invalidates the current JWT token.

---

# User Routes

### 5. Get Current User Profile
```http
GET /api/users/me
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

### 6. Get User
```http
GET /api/users/:id
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
Returns the profile information of a specific user.

---

### 7. Update User
```http
PATCH /api/users/:id
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
Updates a user's profile information.

---

# Player Routes

### 8. Get Current Player
```http
GET /api/players/me
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
Returns the current player's information.

---

### 9. Create Player
```http
POST /api/players
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

### 10. Get Player
```http
GET /api/players/:id
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
Returns a specific player's information.

---

# Game Routes

### 11. List Games
```http
GET /api/games
```

**Response**
```json
[
  {
    "id": 1,
    "name": "Tic Tac Toe",
    "description": "A classic game of X's and O's"
  }
]
```

**Description**  
Returns a list of available games.

---

### 12. Get Game
```http
GET /api/games/:id
```

**Response**
```json
{
  "id": 1,
  "name": "Tic Tac Toe",
  "description": "A classic game of X's and O's"
}
```

**Description**  
Returns information about a specific game.

---

# Game Session Routes

### 13. List Game Sessions
```http
GET /api/games/:game_id/sessions
```

**Response**
```json
[
  {
    "id": 1,
    "game_id": 1,
    "status": "waiting",
    "players": [
      {
        "id": 1,
        "name": "Player 1"
      }
    ]
  }
]
```

**Description**  
Returns a list of game sessions for a specific game.

---

### 14. Create Game Session
```http
POST /api/games/:game_id/sessions
```

**Response**
```json
{
  "id": 1,
  "game_id": 1,
  "status": "waiting",
  "players": [
    {
      "id": 1,
      "name": "Player 1"
    }
  ]
}
```

**Description**  
Creates a new game session for a specific game.

---

### 15. Get Game Session
```http
GET /api/games/:game_id/sessions/:id
```

**Response**
```json
{
  "id": 1,
  "game_id": 1,
  "status": "active",
  "current_player_index": 0,
  "state": {
    "board": [0, 0, 0, 0, 0, 0, 0, 0, 0]
  },
  "players": [
    {
      "id": 1,
      "name": "Player 1"
    },
    {
      "id": 2,
      "name": "Player 2"
    }
  ]
}
```

**Description**  
Returns information about a specific game session.

---

### 16. Update Game Session
```http
PUT /api/games/:game_id/sessions/:id
```

**Request Body**
```json
{
  "game_session": {
    "state": {
      "board": [1, 0, 0, 0, 0, 0, 0, 0, 0]
    },
    "status": "active",
    "current_player_index": 1
  }
}
```

**Response**
```json
{
  "id": 1,
  "game_id": 1,
  "status": "active",
  "current_player_index": 1,
  "state": {
    "board": [1, 0, 0, 0, 0, 0, 0, 0, 0]
  },
  "players": [
    {
      "id": 1,
      "name": "Player 1"
    },
    {
      "id": 2,
      "name": "Player 2"
    }
  ]
}
```

**Description**  
Updates a game session's state.

---

### 17. Join Game Session
```http
POST /api/games/:game_id/sessions/:id/join
```

**Response**
```json
{
  "id": 1,
  "game_id": 1,
  "status": "waiting",
  "players": [
    {
      "id": 1,
      "name": "Player 1"
    },
    {
      "id": 2,
      "name": "Player 2"
    }
  ]
}
```

**Description**  
Joins an existing game session.

---

### 18. Start Game Session
```http
POST /api/games/:game_id/sessions/:id/start
```

**Response**
```json
{
  "id": 1,
  "game_id": 1,
  "status": "active",
  "current_player_index": 0,
  "state": {
    "board": [0, 0, 0, 0, 0, 0, 0, 0, 0]
  },
  "players": [
    {
      "id": 1,
      "name": "Player 1"
    },
    {
      "id": 2,
      "name": "Player 2"
    }
  ]
}
```

**Description**  
Starts a game session that has enough players.

---

### 19. Leave Game Session
```http
DELETE /api/games/:game_id/sessions/:id/leave
```

**Response**
```json
{
  "id": 1,
  "game_id": 1,
  "status": "waiting",
  "players": [
    {
      "id": 1,
      "name": "Player 1"
    }
  ]
}
```

**Description**  
Leaves a game session.

---

# Admin Routes

### 20. List Users (Admin)
```http
GET /api/admin/users
```

**Response**
```json
[
  {
    "id": 1,
    "username": "user123",
    "created_at": "2024-06-01T12:00:00Z"
  }
]
```

**Description**  
Returns a list of all users (admin only).

---

### 21. Create User (Admin)
```http
POST /api/admin/users
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
Creates a new user (admin only).

---

### 22. Get User (Admin)
```http
GET /api/admin/users/:id
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
Returns information about a specific user (admin only).

---

### 23. Update User (Admin)
```http
PATCH /api/admin/users/:id
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
Updates a user's information (admin only).

---

### 24. Make User Admin
```http
POST /api/admin/users/:id/make_admin
```

**Response**
```json
{
  "id": 1,
  "username": "user123",
  "is_admin": true
}
```

**Description**  
Makes a user an admin (admin only).

---

### 25. Remove User Admin
```http
POST /api/admin/users/:id/remove_admin
```

**Response**
```json
{
  "id": 1,
  "username": "user123",
  "is_admin": false
}
```

**Description**  
Removes admin privileges from a user (admin only).

---

### 26. Create Game (Admin)
```http
POST /api/admin/games
```

**Request Body**
```json
{
  "name": "Tic Tac Toe",
  "description": "A classic game of X's and O's"
}
```

**Response**
```json
{
  "id": 1,
  "name": "Tic Tac Toe",
  "description": "A classic game of X's and O's"
}
```

**Description**  
Creates a new game (admin only).

---

### 27. Update Game (Admin)
```http
PATCH /api/admin/games/:id
```

**Request Body**
```json
{
  "name": "Updated Game Name",
  "description": "Updated game description"
}
```

**Response**
```json
{
  "id": 1,
  "name": "Updated Game Name",
  "description": "Updated game description"
}
```

**Description**  
Updates a game's information (admin only).

---

### 28. Delete Game (Admin)
```http
DELETE /api/admin/games/:id
```

**Description**  
Deletes a game (admin only).

---

### 29. Update Game Schema (Admin)
```http
POST /api/admin/games/:id/schema
```

**Request Body**
```json
{
  "schema": {
    "type": "object",
    "properties": {
      "board": {
        "type": "array",
        "items": {
          "type": "integer"
        }
      }
    }
  }
}
```

**Response**
```json
{
  "id": 1,
  "name": "Tic Tac Toe",
  "schema": {
    "type": "object",
    "properties": {
      "board": {
        "type": "array",
        "items": {
          "type": "integer"
        }
      }
    }
  }
}
```

**Description**  
Updates a game's state schema (admin only).

---

### 30. Cleanup Game Sessions (Admin)
```http
POST /api/admin/game_sessions/cleanup
```

**Description**  
Cleans up abandoned game sessions (admin only).

---

### 31. Delete Game Session (Admin)
```http
DELETE /api/admin/game_sessions/:id
```

**Description**  
Deletes a specific game session (admin only).

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
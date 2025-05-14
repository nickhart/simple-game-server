# SimpleGameServer Architecture

## Overview

SimpleGameServer is a Ruby on Rails application built using Rails API mode. It provides a REST API for managing multiplayer games with JWT-based authentication and role-based access control (admin/player). The game logic is extensible, supporting different game types via JSON-based game state management. The server handles authentication, authorization, and turn management while allowing flexible client-driven game state updates.

## Project Structure

```
simple_game_server/
├── app/                    # Application code
│   ├── models/             # Data models and business logic
│   ├── controllers/        # API endpoints and request handling (namespaced under Api/)
│   ├── services/           # Service objects encapsulating business logic
│   ├── lib/                # Custom libraries and modules
├── config/                 # Rails configuration files
├── db/                     # Database migrations and schema
├── spec/                   # RSpec tests and support files
├── examples/               # Example game implementations
│   └── tic_tac_toe/        # Tic Tac Toe game example
├── public/                 # Public static files (minimal usage)
├── ROUTES.md               # API documentation
└── ARCHITECTURE.md         # Architecture documentation
```

## Core Components

### Models

#### Game
`app/models/game.rb`
- Defines available games and their configuration
- Key attributes:
  - `name`: Name of the game
  - `description`: Game description
  - `state_schema`: JSON schema for validating game state
  - `min_players`: Minimum players required to start the game
  - `max_players`: Maximum players allowed in the game

#### GameSession
`app/models/game_session.rb`
- Central model managing game state and metadata
- Handles game logic, turn management, and win conditions via client-driven JSON state
- Supports different game types through association with `Game`
- Key attributes:
  - `game_id`: Reference to the `Game` model
  - `status`: Current game state (`waiting`, `active`, `finished`)
  - `state`: JSONB column storing game-specific state data
  - `current_player_index`: Index of the current player's turn
  - `winner_id`: ID of the winning player (nullable)
  - `creator_id`: References the `Player` who created the game session

#### Player
`app/models/player.rb`
- Represents a player entity linked to a user
- Uses UUID as primary key
- Has a one-to-one relationship with `User`
- Participates in multiple game sessions through `GamePlayer` join model

#### User
`app/models/user.rb`
- Authentication model
- Has many `Tokens` for JWT session management
- Optionally has one associated `Player`
- Includes a `role` column to distinguish `admin` and `player` roles

#### Token
`app/models/token.rb`
- Stores versioned JWT tokens with expiration for session management
- Attributes include token `jti` (JWT ID), token type, expiration timestamp, and association to `User`
- Enables token revocation and tracking

### Controllers

Controllers are namespaced under `Api::` to reflect API-only architecture.

#### Api::GameSessionsController
- Manages game session lifecycle and player interactions
- Key actions:
  - `index`: List game sessions for a specific game
  - `show`: Retrieve details of a specific game session
  - `create`: Create a new game session
  - `join`: Join an existing game session
  - `start`: Start a game session (requires the session to be in `waiting` status and player count within limits)
  - `update`: Update game state or status (including moves)
  - `leave`: Leave a game session

#### Api::PlayersController
- Handles player-related operations
- Key actions:
  - `create`: Create a player profile linked to a user
  - `show`: Retrieve player details
  - `me`: Get current player's details

#### Api::TokensController
- Manages JWT token lifecycle
- Key actions:
  - `login`: Authenticate and issue JWT token
  - `refresh`: Refresh an existing token
  - `logout`: Revoke JWT token

#### Api::UsersController
- Manages user registration and profile
- Key actions:
  - `create`: Register a new user
  - `show`: Get user details
  - `update`: Update user profile
  - `me`: Get current user's details

#### Api::Admin::UsersController
- Admin-specific user management endpoints
- Key actions:
  - List users
  - Manage user roles
  - Perform administrative user operations

#### Api::Admin::GamesController
- Admin-specific game management endpoints
- Key actions:
  - Create games
  - Update games
  - Delete games
  - Update game schemas

### Authentication and Roles

- JWT-based session management with versioned tokens stored in the `Token` model
- Players are created separately from users and are required to participate in games
- Admin users do not automatically have associated `Player` records
- Role-based access control enforced via `role` attribute on `User` (`admin` or `player`)

## Database Schema

### games
- `id`: Primary key
- `name`: string
- `description`: string
- `state_schema`: jsonb
- `min_players`: integer
- `max_players`: integer
- timestamps

### game_sessions
- `id`: Primary key
- `game_id`: integer (foreign key to games)
- `status`: string
- `state`: jsonb
- `current_player_index`: integer
- `winner_id`: uuid (foreign key to players)
- `creator_id`: uuid (foreign key to players)
- timestamps

### players
- `id`: uuid primary key
- `user_id`: uuid (foreign key to users)
- `name`: string
- timestamps

### users
- `id`: uuid primary key
- `username`: string, unique
- `encrypted_password`: string
- `role`: string (`admin` or `player`)
- timestamps

### tokens
- `id`: primary key
- `user_id`: uuid (foreign key to users)
- `jti`: string (JWT ID)
- `token_type`: string
- `expires_at`: datetime
- timestamps

### game_players
- `id`: primary key
- `game_session_id`: integer (foreign key)
- `player_id`: uuid (foreign key)
- timestamps

## Testing

- Uses RSpec for unit, integration, and system tests
- FactoryBot for test data creation
- Includes a `FactoryHelpers` module providing helpers such as `create_user_with_player!` to streamline test setup

## Web Interface

The application is API-only and does not include a built-in web UI. Any web interface is expected to be implemented separately or as a client consuming the API.

## API Documentation

The API is documented in `ROUTES.md`, which includes:
- Detailed endpoint descriptions
- Request/response examples
- TypeScript interfaces
- Error handling
- Authentication requirements

## API Expectations and Conventions

- All API requests and responses use JSON
- `player_id` and other IDs use UUID format
- Authentication via Bearer tokens in headers
- Role-based access enforced on endpoints
- Game state updates are submitted via `PUT /api/games/:game_id/sessions/:id`
- Game state is validated against the game's JSON schema

## Authentication Flow

- User registration handled via `Api::UsersController`
- Login and token management via `Api::TokensController`
- JWT tokens issued upon login and stored with versioning in `Token` model
- Player creation is a separate step after user registration, required to participate in games
- Admin users have elevated privileges but no default player entity

## Game State Management

- The game state is fully managed by the client and stored as JSON in the `state` column of `GameSession`
- The server validates state updates against the game's JSON schema
- The server manages turn order, game status, and player participation but does not interpret game-specific state
- Status values: `waiting`, `active`, `finished`
- Turn management via `current_player_index`

## Error Responses

Standardized error responses include:

```json
{
  "error": "Resource not found"
}
```
Status: 404 Not Found

```json
{
  "error": "Unauthorized access"
}
```
Status: 401 Unauthorized

```json
{
  "error": "Validation failed: ..."
}
```
Status: 422 Unprocessable Entity
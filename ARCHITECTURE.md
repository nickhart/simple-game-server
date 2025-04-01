# SimpleGameServer Architecture

## Overview

SimpleGameServer is a Ruby on Rails application that provides a REST API for managing multiplayer games. The server is designed to be extensible, currently supporting TicTacToe with the ability to add more game types in the future. In addition to the API, it includes a web-based management interface for monitoring and managing game sessions.

## Project Structure

```
simple_game_server/
├── app/                    # Application code
│   ├── models/            # Data models and business logic
│   ├── controllers/       # API endpoints and request handling
│   ├── views/            # Web interface templates for game management
│   ├── javascript/       # Client-side JavaScript for web interface
│   └── assets/           # Static assets and styling for web interface
├── config/               # Rails configuration files
├── db/                   # Database migrations and schema
├── test/                # Test suite
├── public/              # Public static files
├── API.md               # API documentation
└── openapi.yaml         # OpenAPI/Swagger specification
```

## Core Components

### Models

#### GameSession
`app/models/game_session.rb`
- Central model for managing game state
- Handles game logic, turn management, and win conditions
- Supports different game types (currently TicTacToe)
- Key attributes:
  - `game_type`: Type of game (e.g., "tictactoe")
  - `status`: Current game state (waiting, in_progress, completed)
  - `board`: Game board state
  - `current_player_index`: Index of the current player's turn
  - `winner_id`: ID of the winning player (if game is completed)

#### Player
`app/models/player.rb`
- Represents a player in the system
- Can participate in multiple game sessions
- Connected to game sessions through GamePlayer join model

#### GamePlayer
`app/models/game_player.rb`
- Join model connecting Players and GameSessions
- Tracks player-specific game information
- Manages player order and game piece assignments

### Controllers

#### GameSessionsController
`app/controllers/game_sessions_controller.rb`
- Handles all game-related API endpoints
- Key actions:
  - `index`: List all game sessions
  - `show`: Get details of a specific game
  - `create`: Start a new game
  - `join`: Join an existing game
  - `move`: Make a move in the game
  - `cleanup`: Remove unused game sessions

#### ApplicationController
`app/controllers/application_controller.rb`
- Base controller providing shared functionality
- Handles authentication and error responses

### Web Interface

The application includes a web-based management interface for monitoring and managing game sessions:

#### Views (`app/views/`)
- `game_sessions/index.html.erb`: List of all game sessions
- `game_sessions/show.html.erb`: Detailed view of a game session
- `game_sessions/new.html.erb`: Form for creating new game sessions
- `layouts/application.html.erb`: Main application layout

#### JavaScript (`app/javascript/`)
- `application.js`: Main JavaScript entry point
- `controllers/`: Stimulus controllers for interactive features
  - `application.js`: Base Stimulus controller setup
  - `hello_controller.js`: Example controller (can be removed)
  - `index.js`: Controller registration

#### Assets (`app/assets/`)
- Stylesheets and other static assets for the web interface
- Currently using Bootstrap for styling

## Database Schema

### game_sessions
- `id`: Primary key
- `game_type`: string
- `status`: string
- `board`: jsonb
- `current_player_index`: integer
- `winner_id`: integer (foreign key to players)
- timestamps

### players
- `id`: Primary key
- `name`: string
- timestamps

### game_players
- `id`: Primary key
- `game_session_id`: integer (foreign key)
- `player_id`: integer (foreign key)
- timestamps

## API Documentation

The API is documented in two formats:
1. `API.md`: Markdown documentation with examples and explanations
2. `openapi.yaml`: OpenAPI/Swagger specification for automated tooling

## Testing

The test suite is organized into:
- Unit tests for models
- Integration tests for controllers
- System tests for end-to-end scenarios

Tests can be run using:
```bash
bin/rails test
```

## Development Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```
3. Set up the database:
   ```bash
   bin/rails db:setup
   ```
4. Start the server:
   ```bash
   bin/rails server
   ```

## Security

Security measures are documented in `SECURITY.md`, including:
- Authentication requirements
- Rate limiting
- Input validation
- CSRF protection

## Future Considerations

1. Support for additional game types
2. Real-time updates for game state changes
3. Player statistics and leaderboards
4. Game replay functionality
5. AI opponents
6. Enhanced web interface features:
   - Real-time game viewing
   - Player management dashboard
   - Game analytics and statistics
   - Custom game type configuration 
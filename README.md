# Simple Game Server

[![Ruby](https://img.shields.io/badge/Ruby-3.2.2-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-7.1.3-red.svg)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Table of Contents

- [Simple Game Server](#simple-game-server)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Game Configuration](#game-configuration)
    - [Bootstrapping](#bootstrapping)
    - [Creating a New Game Type](#creating-a-new-game-type)
    - [State Schema Types](#state-schema-types)
    - [Example: Tic Tac Toe Configuration](#example-tic-tac-toe-configuration)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Running the Server](#running-the-server)
    - [CSRF Protection Configuration](#csrf-protection-configuration)
    - [RESTful API Design](#restful-api-design)
  - [Testing](#testing)
    - [Test Directory Structure](#test-directory-structure)
      - [Key Test Files](#key-test-files)
      - [Testing Approach](#testing-approach)
  - [Example Implementation](#example-implementation)
  - [AI-Assisted Development](#ai-assisted-development)
    - [Project Setup and Configuration](#project-setup-and-configuration)
    - [Server Development](#server-development)
    - [Example Game Implementation](#example-game-implementation)
  - [Developer Cheat Sheet](#developer-cheat-sheet)
    - [Server Commands](#server-commands)
    - [Database Commands](#database-commands)
    - [Testing Commands](#testing-commands)
    - [Linting Commands](#linting-commands)
    - [Development Tools](#development-tools)
  - [Contributing](#contributing)
  - [Future Plans](#future-plans)
    - [Short Term](#short-term)
    - [Medium Term](#medium-term)
    - [Long Term](#long-term)
  - [License](#license)

A simple game server built with Ruby on Rails, designed to handle multiplayer game sessions. This server provides a flexible API for managing game sessions, players, and game state, while remaining agnostic to the specific game logic.

## Features

- Player authentication and management
- Game session creation and management
- Flexible game state storage with JSON schema validation
- Turn-based game support
- Example Tic Tac Toe implementation
- Decoupled User and Player models (Player created via separate API endpoint)
- UUID-based identifiers for Player and Token models
- Role-based access (admin vs player)
- JSON API with consistent error handling
- Fully RESTful API for managing game resources (sessions, players, turns)
- Custom member routes for domain-specific actions (`start`, `join`, `leave`) with semantic HTTP verbs

## Game Configuration

The server supports configurable game types through the `Game` model. Each game type defines:
- Minimum and maximum players
- Game state schema for validation
- Game-specific rules and logic

### Bootstrapping

To create the first admin user, make a POST request to `/api/admin/users` with a username and password. This only works when no users exist.

### Creating a New Game Type

1. Start the Rails console:
```bash
rails console
```

2. Create a new game with its configuration:
```ruby
# Create the game with state schema
game = Game.create!(
  name: "YourGameName",
  description: "Description of your game",
  min_players: 2,
  max_players: 4,
  state_schema: {
    type: "object",
    properties: {
      board: {
        type: "array",
        items: {
          type: "integer"
        }
      },
      scores: {
        type: "object",
        additionalProperties: {
          type: "integer"
        }
      },
      current_player: {
        type: "integer"
      },
      game_status: {
        type: "string"
      }
    }
  }
)
```

### State Schema Types

The state schema uses JSON Schema format and supports the following types:
- `array`: For lists like game boards or move history
- `object`: For key-value pairs like scores or player data
- `integer`: For numeric values like player indices or scores
- `string`: For text values like game status or messages
- `boolean`: For true/false values

### Example: Tic Tac Toe Configuration

```ruby
game = Game.create!(
  name: "Tic Tac Toe",
  description: "A classic game of X's and O's",
  min_players: 2,
  max_players: 2,
  state_schema: {
    type: "object",
    properties: {
      board: {
        type: "array",
        items: {
          type: "integer"
        },
        minItems: 9,
        maxItems: 9
      }
    }
  }
)
```

## Requirements

- Ruby 3.2.2
- Rails 7.1.3
- PostgreSQL 15
- Node.js (for asset compilation)
- Yarn (for JavaScript dependencies)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/simple_game_server.git
cd simple_game_server
```

2. Install Ruby dependencies:
```bash
bundle install
```

3. Install JavaScript dependencies:
```bash
yarn install
```

4. Set up the database:
```bash
rails db:create db:migrate
```

5. Configure environment variables:
```bash
cp .env.example .env
```
Edit `.env` with your configuration (database credentials, JWT secret, etc.)

## Running the Server

Start the Rails server:
```bash
rails server
```

The server will be available at `http://localhost:3000`

The server uses JWT-based authentication for API requests. CSRF protection is disabled by default for API usage since token-based authentication is used instead of session-based authentication.

### CSRF Protection Configuration

By default, CSRF (Cross-Site Request Forgery) protection is disabled for API requests. This is because the API uses token-based authentication (JWT) instead of session-based authentication, which is the typical use case for CSRF protection.

You can control CSRF protection through the `ENABLE_CSRF_PROTECTION` environment variable:

```bash
# Enable CSRF protection
ENABLE_CSRF_PROTECTION=true rails server

# Disable CSRF protection (default)
ENABLE_CSRF_PROTECTION=false rails server
```

**Note for Local Development and Testing:**
- CSRF protection is disabled by default to simplify local development and testing
- When deploying to production, consider enabling CSRF protection if your API will be accessed from web browsers
- For API-only applications accessed by mobile apps or other services, CSRF protection is typically not needed

### RESTful API Design

The server adheres to REST principles for clarity and consistency. Resources are exposed via standard HTTP methods:

- `GET /api/games`: List available games
- `GET /api/games/:id`: Get game details
- `POST /api/games/:game_id/sessions`: Create a new game session
- `GET /api/games/:game_id/sessions/:id`: Show a specific session
- `PUT /api/games/:game_id/sessions/:id`: Update a session's state
- `POST /api/games/:game_id/sessions/:id/start`: Start the session
- `POST /api/games/:game_id/sessions/:id/join`: Join the session as a player
- `DELETE /api/games/:game_id/sessions/:id/leave`: Leave the session

These member routes allow domain-specific state transitions (e.g., starting or joining a session) while maintaining a RESTful structure.

## Testing

### Test Directory Structure

```
spec/                           # Main test directory
├── spec_helper.rb             # Core RSpec configuration
├── rails_helper.rb            # Rails-specific test setup
├── controllers/               # Controller tests
│   └── api/                   # API controller tests
│       ├── tokens_controller_spec.rb    # Authentication tests
│       ├── users_controller_spec.rb     # User management tests
│       ├── players_controller_spec.rb   # Player management tests
│       ├── games_controller_spec.rb     # Game management tests
│       └── game_sessions_controller_spec.rb # Game session tests
├── models/                    # Model tests
├── factories/                 # Factory definitions
│   ├── users.rb              # User factory
│   ├── games.rb              # Game factory
│   ├── game_sessions.rb      # Game session factory
│   ├── players.rb            # Player factory
│   └── tokens.rb             # Token factory
└── support/                   # Test support files
    ├── controller_macros.rb  # Controller authentication helpers
    ├── authentication_helper.rb # Authentication utilities
    ├── database_cleaner.rb   # Database cleaning configuration
    ├── factory_bot.rb        # FactoryBot setup
    ├── helpers/              # Test helper modules
    │   ├── authentication_helper.rb # Authentication test helpers
    │   └── json_helper.rb    # JSON response helpers
    └── shared_contexts/      # Shared test contexts
```

#### Key Test Files

1. **Configuration Files**:
   - `spec_helper.rb`: Core RSpec configuration
   - `rails_helper.rb`: Rails-specific test setup
   - `.rspec`: RSpec command-line options
   - `.rubocop.yml`: Code style configuration

2. **Controller Tests**:
   - `tokens_controller_spec.rb`: Tests for authentication endpoints
   - `users_controller_spec.rb`: Tests for user management
   - `players_controller_spec.rb`: Tests for player management
   - `games_controller_spec.rb`: Tests for game management
   - `game_sessions_controller_spec.rb`: Tests for game session management

3. **Support Files**:
   - `controller_macros.rb`: Authentication helpers for controller tests
   - `authentication_helper.rb`: JWT token management utilities
   - `database_cleaner.rb`: Database cleaning configuration
   - `factory_bot.rb`: FactoryBot setup and configuration

4. **Helper Modules**:
   - `authentication_helper.rb`: Authentication test utilities
   - `json_helper.rb`: JSON response parsing helpers

5. **Factories**:
   - `users.rb`: User model factory
   - `games.rb`: Game model factory
   - `game_sessions.rb`: Game session factory
   - `players.rb`: Player model factory
   - `tokens.rb`: Token model factory

#### Testing Approach

Our test suite is built on RSpec and follows a comprehensive testing strategy:

1. **Framework & Tools**:
   - RSpec for test framework
   - FactoryBot for test data generation
   - Database Cleaner for test database management
   - Custom authentication helpers for API testing

2. **Configuration**:
   - `spec_helper.rb`: Core RSpec configuration
     - Custom matcher descriptions enabled
     - Partial double verification enabled
     - Shared context metadata behavior configured
   - `rails_helper.rb`: Rails-specific configuration
     - Transactional fixtures enabled
     - Automatic spec type inference
     - FactoryBot integration
     - Support file autoloading

3. **Test Organization**:
   - Models: Unit tests for ActiveRecord models
   - Controllers: API endpoint testing
   - Factories: Test data definitions
   - Support: Shared test utilities and helpers

4. **Custom Test Infrastructure**:
   - `ControllerMacros`: Authentication helpers for controller tests
   - `AuthenticationHelper`: JWT token management for API tests
   - `JSONHelper`: Response parsing utilities
   - `DatabaseCleaner`: Ensures clean test state

5. **UUID Usage**:
   - Player and Token records use UUIDs as identifiers
   - Player must be explicitly created for a user before they can join or create game sessions
   - Specs rely on `create_user_with_player!` helper to set up users with associated players

6. **CI Integration**:
   - GitHub Actions workflow
   - PostgreSQL test database
   - Automated schema loading
   - Security scanning (Brakeman, importmap audit)

7. **Running Tests**:
   - Local development: `bundle exec rspec`
   - CI environment: `script/test_ci`
     - Matches GitHub Actions environment
     - Uses fresh database for each run
     - Cleans up after tests
     - Supports all RSpec options

The test suite emphasizes:
- API authentication and authorization
- Data integrity and validation
- Clean test isolation
- Comprehensive coverage of business logic
- Automated security checks

## Example Implementation

The repository includes a Tic Tac Toe example implementation in the `/examples/tic_tac_toe` directory. This example demonstrates:
- Game session management
- Turn-based gameplay
- State management with JSON schema validation
- Client-server communication
- Error handling and game state validation

See the [Tic Tac Toe README](examples/tic_tac_toe/README.md) for implementation details.

## AI-Assisted Development

This project has been developed with the assistance of generative AI to accelerate development and ensure best practices. AI has been used to:

### Project Setup and Configuration
- Configure RuboCop for code style enforcement
- Set up GitHub Actions for CI/CD
- Configure branch protection rules
- Generate initial project structure

### Server Development
- Design and implement RESTful API endpoints
- Create database migrations and models
- Implement authentication and authorization
- Write comprehensive test suites
- Generate API documentation

### Example Game Implementation
- Design the Tic Tac Toe game client
- Implement game logic and state management
- Create test cases for game functionality
- Generate client-side documentation

The AI assistance has helped maintain consistent code quality, follow Rails best practices, and ensure comprehensive test coverage while allowing for rapid development and iteration.

## Developer Cheat Sheet

### Server Commands
```bash
# Start server in development mode
rails server
# or
bin/rails server

# Start server with debug logging
RAILS_LOG_LEVEL=debug bin/rails server

# Start server on specific port
rails server -p 3001

# Start server in production mode
RAILS_ENV=production rails server
```

### Database Commands
```bash
# Create database
rails db:create

# Run migrations
rails db:migrate

# Rollback last migration
rails db:rollback

# Reset database (drop, create, migrate)
rails db:reset

# Seed database
rails db:seed

# View database schema
rails db:schema:dump

# Rebuild database with UUIDs
rails db:drop db:create db:migrate
```

### Testing Commands
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/game_session_spec.rb

# Run specific test method
bundle exec rspec spec/models/game_session_spec.rb:123

# Run tests with coverage
COVERAGE=true bundle exec rspec
```

### Linting Commands
```bash
# Run RuboCop
bundle exec rubocop

# Run RuboCop with auto-correct
bundle exec rubocop -a

# Run RuboCop with auto-correct and unsafe changes
bundle exec rubocop -A

# Check specific file
bundle exec rubocop app/models/game_session.rb
```

### Development Tools
```bash
# Start Rails console
rails console

# Start Rails console in sandbox mode (rollback changes)
rails console --sandbox

# Generate new migration
rails generate migration AddColumnToTable

# Generate new model
rails generate model ModelName

# Generate new controller
rails generate controller ControllerName
```

## Contributing

This project is currently in its early stages as a learning exercise and to support multiplayer functionality in some mobile games. While the focus is on personal development, I'm open to:
- Feedback and suggestions
- Questions about implementation
- Potential contributions that align with the project's goals

If you're interested in contributing, please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with a clear description of your changes

Note: This project uses UUIDs for certain tables. If modifying schema, ensure proper UUID handling.

## Future Plans

### Short Term
- Improve game session cleanup/removal
- Enhanced handling of joining/leaving/rejoining games
- Better error handling and validation
- Documentation improvements

### Medium Term
- Real-time updates using WebSockets
- Push notifications for game events
- Enhanced player presence tracking
- Game session persistence and recovery

### Long Term
- Support for different game types
- Game analytics and statistics
- Player management dashboard
- Custom game type configuration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

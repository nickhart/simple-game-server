# Simple Game Server

[![Ruby](https://img.shields.io/badge/Ruby-3.2.2-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-7.1.3-red.svg)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A simple game server built with Ruby on Rails, designed to handle multiplayer game sessions. This server provides a flexible API for managing game sessions, players, and game state, while remaining agnostic to the specific game logic.

## Features

- Player authentication and management
- Game session creation and management
- Flexible game state storage
- Turn-based game support
- Example Tic Tac Toe implementation

## Game Configuration

The server supports configurable game types through the `Game` and `GameConfiguration` models. Each game type defines:
- Minimum and maximum players
- Game state schema
- Game-specific rules and logic

### Creating a New Game Type

1. Start the Rails console:
```bash
rails console
```

2. Create a new game with its configuration:
```ruby
# Create the game
game = Game.create!(
  name: "YourGameName",
  min_players: 2,
  max_players: 4
)

# Create the game configuration with state schema
game_config = GameConfiguration.create!(
  game: game,
  state_schema: {
    # Define your game state structure here
    # Example for a board game:
    board: [],  # Array type for the game board
    scores: {},  # Hash type for player scores
    current_player: { type: :integer },  # Integer type for current player index
    game_status: { type: :string }  # String type for game status
  }
)
```

### State Schema Types

The state schema supports the following types:
- `Array`: For lists like game boards or move history
- `Hash`: For key-value pairs like scores or player data
- `{ type: :integer }`: For numeric values like player indices or scores
- `{ type: :string }`: For text values like game status or messages
- `{ type: :boolean }`: For true/false values

### Example: Tic Tac Toe Configuration

```ruby
game = Game.create!(
  name: "Tic Tac Toe",
  min_players: 2,
  max_players: 2
)

game_config = GameConfiguration.create!(
  game: game,
  state_schema: {
    board: [],  # Array for the 3x3 board
    winner: { type: :integer }  # Integer for winner index (0 or 1) or nil for draw
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

## Testing

### Unit Tests
Run the test suite:
```bash
rails test
```

### API Testing with Postman
The project includes Postman collections for testing the API endpoints. These can be used to:
- Test the API locally
- Verify API behavior against a deployed instance
- Document API usage
- Automate API testing

To use the Postman tests:
1. Install [Postman](https://www.postman.com/)
2. Import the collection from `test/postman/simple_game_server.postman_collection.json`
3. Set up environment variables in Postman:
   - `base_url`: Your server URL (e.g., `http://localhost:3000`)
   - `token`: JWT token (will be set automatically after login)

## Example Implementation

The repository includes a Tic Tac Toe example implementation in the `/examples/tic_tac_toe` directory. This example demonstrates:
- Game session management
- Turn-based gameplay
- State management
- Client-server communication

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
```

### Testing Commands
```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/game_session_test.rb

# Run specific test method
rails test test/models/game_session_test.rb:123

# Run tests with coverage
COVERAGE=true rails test
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

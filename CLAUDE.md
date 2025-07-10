# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Development Server
```bash
# Start Rails server
rails server

# Start Rails console
rails console

# Start Rails console in sandbox mode (rollback changes)
rails console --sandbox
```

### Database
```bash
# Setup database
rails db:create db:migrate

# Reset database (includes UUIDs)
rails db:drop db:create db:migrate

# Run migrations
rails db:migrate

# Rollback last migration
rails db:rollback

# Seed database
rails db:seed
```

### Testing
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/game_session_spec.rb

# Run specific test method
bundle exec rspec spec/models/game_session_spec.rb:123

# Run CI test script (matches GitHub Actions)
script/test_ci

# Run tests with coverage
COVERAGE=true bundle exec rspec
```

### Code Quality
```bash
# Run RuboCop linter
bundle exec rubocop

# Run RuboCop with auto-correct
bundle exec rubocop -a

# Run RuboCop with unsafe auto-correct
bundle exec rubocop -A

# Run security scanner
bundle exec brakeman

# Run code smell detector
bundle exec reek
```

### Frontend Assets
```bash
# Build CSS
yarn build:css

# Watch CSS for changes
yarn watch:css
```

## Architecture Overview

### Core Models
- **User**: Authentication model using Devise with JWT
- **Player**: Game participant model (UUID), separate from User
- **Game**: Game type configuration with JSON schema validation
- **GameSession**: Individual game instances with state management
- **GamePlayer**: Join table between Player and GameSession
- **Token**: JWT token management (UUID)

### Key Relationships
- User has_one Player (must be explicitly created)
- Game has_many GameSessions
- GameSession belongs_to Game, has_many Players through GamePlayer
- Players use UUIDs as primary keys
- Tokens use UUIDs as primary keys

### API Structure
- RESTful API under `/api` namespace
- JWT-based authentication
- Admin namespace for administrative operations
- CSRF protection disabled by default for API usage
- Consistent JSON error responses

### Game State Management
- Games define state_schema using JSON Schema format
- GameSessions store game state as JSON
- State validation occurs on updates
- Turn-based gameplay support

### Authentication Flow
1. User registration/login via `/api/tokens/login`
2. Player creation via `/api/players` (required before game participation)
3. JWT token used for subsequent API requests
4. Admin users have elevated permissions

### Database Notes
- Uses PostgreSQL with UUID support
- Player and Token models use UUIDs as primary keys
- Schema includes proper UUID handling and constraints
- Database must be reset when modifying UUID-related migrations

### Testing Infrastructure
- RSpec for testing framework
- FactoryBot for test data
- DatabaseCleaner for test isolation
- Custom authentication helpers for API testing
- Comprehensive controller and model test coverage
- CI script matches GitHub Actions environment

### Transport Layer Development (Current Focus)
- Currently on `transport_layer` branch implementing **hybrid architecture**
- **Pattern**: REST for management APIs, WebSocket for real-time gameplay
- **Current state**: Action Cable implementation (interim solution)
- **Goal**: Protocol-agnostic WebSocket API for cross-platform support

#### Architecture Overview
```
Management Layer (REST):           Gameplay Layer (WebSocket):
├── User registration/login       ├── Move submission
├── Game creation/configuration   ├── State synchronization  
├── Session management            ├── Turn notifications
├── Player profiles               └── Game events
└── Admin operations
```

#### Implementation Status
- ✅ **Action Cable WebSocket infrastructure** - GameSessionChannel implemented
- ✅ **Server-side broadcasting** - Sessions controller broadcasts state changes
- ✅ **Ruby client library** - Gemified with WebSocket support
- ✅ **Cross-platform clients** - Dart SDK generated
- 🔄 **Integration testing** - WebSocket functionality needs end-to-end testing
- 📋 **Protocol migration** - 6-phase plan to replace Action Cable with standard WebSocket

#### Testing WebSocket Functionality
```bash
# Test Action Cable connection
rails console
# In console: ApplicationCable::GameSessionChannel.broadcast_update(game_session)

# Test Ruby client (in examples/tic_tac_toe/)
bundle install
ruby main.rb  # Should connect via WebSocket

# Test server broadcasting
curl -X PUT /api/games/1/sessions/1 -H "Authorization: Bearer TOKEN" -d '{"state": {...}}'
# Should trigger WebSocket broadcast
```

### Example Implementation
- Tic Tac Toe example in `/examples/tic_tac_toe/`
- Demonstrates game session management and client-server communication
- Uses Ruby client library for API interaction
- Shows proper game state management patterns

## Development Notes

### UUID Usage
- Always use UUIDs for Player and Token models
- When creating test data, use `create_user_with_player!` helper
- Database setup requires proper UUID extension configuration

### State Schema Design
- Use JSON Schema format for game state validation
- Support for arrays, objects, integers, strings, booleans
- Define proper constraints (minItems, maxItems, etc.)
- Validate state transitions in game logic

### API Design Patterns
- Use semantic HTTP verbs for actions
- Member routes for domain-specific operations (start, join, leave)
- Consistent error handling and response format
- Proper authentication and authorization checks

### Security Considerations
- JWT tokens for API authentication
- Admin authorization for sensitive operations
- Input validation using JSON Schema
- CSRF protection configurable via environment variable
- Regular security scanning with Brakeman

## WebSocket Development Path Forward

### Immediate Testing Steps
1. **Test Current Action Cable Implementation**
   ```bash
   # Start server with WebSocket enabled
   rails server
   
   # Test client connection (in examples/tic_tac_toe/)
   cd examples/tic_tac_toe
   bundle install
   ruby main.rb
   ```

2. **Verify WebSocket Broadcasting**
   - Make REST API call to update game session
   - Confirm WebSocket client receives real-time update
   - Check Rails logs for broadcast messages

3. **Test Cross-Platform Clients**
   ```bash
   # Test Dart client
   cd clients/dart
   dart pub get
   dart run # If example exists
   ```

### Development Priorities (Recommended Order)

#### **Phase 1: Complete Action Cable Integration** (1-2 weeks)
- **Goal**: Get current WebSocket implementation fully working
- **Tasks**:
  - Fix any integration issues in tic-tac-toe example
  - Add WebSocket connection testing
  - Verify broadcasting works end-to-end
  - Document WebSocket API in OpenAPI spec

#### **Phase 2: Protocol-Agnostic Migration Planning** (1 week)
- **Goal**: Prepare for standard WebSocket implementation
- **Tasks**:
  - Design JSON message schema (subscribe, unsubscribe, player_move, game_session_update)
  - Create WebSocket controller using `faye-websocket`
  - Add route for `/ws/game_session`
  - Test basic WebSocket connection with `wscat`

#### **Phase 3: Dual Protocol Support** (2-3 weeks)
- **Goal**: Run both Action Cable and standard WebSocket
- **Tasks**:
  - Implement server-side message handling
  - Update Ruby client to support both protocols
  - Add protocol selection configuration
  - Create protocol migration guide

#### **Phase 4: Cross-Platform Clients** (2-4 weeks)
- **Goal**: Native mobile support
- **Tasks**:
  - Create iOS WebSocket client (Swift)
  - Create Android WebSocket client (Kotlin)
  - Update Flutter/Dart client for standard WebSocket
  - Add authentication via JWT in WebSocket handshake

#### **Phase 5: Production Readiness** (1-2 weeks)
- **Goal**: Harden WebSocket implementation
- **Tasks**:
  - Add connection limits and timeouts
  - Implement proper error handling
  - Add monitoring and metrics
  - Performance testing with multiple clients

### Testing Strategy
```bash
# Quick WebSocket test with wscat
npm install -g wscat
wscat -c ws://localhost:3000/cable  # Action Cable
wscat -c ws://localhost:3000/ws/game_session  # Future standard WebSocket

# Load testing
# Use artillery.io or similar for WebSocket load testing
```

### Key Decision Points
1. **Action Cable vs Standard WebSocket**: Start with Action Cable, migrate when ready
2. **Authentication**: JWT in WebSocket handshake or initial message
3. **Error Handling**: Consistent error format across REST and WebSocket
4. **Scaling**: Consider `anycable` for production WebSocket scaling
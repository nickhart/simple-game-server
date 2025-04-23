# Simple Game Server - Constraints and Architectural Decisions

## Database Constraints

### PostgreSQL
- **Version**: PostgreSQL 15
- **Storage Engine**: Uses PostgreSQL's native JSONB type for flexible game state storage
- **Schema Design**:
  - Uses Rails migrations for schema management
  - Follows Rails conventions for table naming and relationships
  - Implements foreign key constraints for data integrity

### Data Models
- **Game**:
  - Stores game metadata and rules
  - sets min/max players
  - can specify a json schema for the game state, which will be enforced by the API
- **GameSession**:
  - Stores game state in JSONB format
  - Maintains player relationships through join table
  - Tracks game status and current player
  - Can specify min/max players for the session as long as they are within the Game's min/max player
- **User**:
  - Primary key remains as `bigint` (default Rails behavior)
  - Can have zero or one associated Player (not created automatically)
  - Uses Devise for authentication
  - Includes a `role` field (either "admin" or "player") to distinguish user capabilities
- **Token**:
  - Belongs to User via `user_id` (bigint)
  - Uses JWT `jti` field for unique token validation
  - Includes `ON DELETE CASCADE` behavior for automatic cleanup when the user is deleted
- **Player**:
  - Uses UUID as the primary key for increased security and to prevent ID guessability
  - Belongs to a User via `user_id` (bigint)
  - Enforces a one-to-one relationship with User via `UNIQUE` constraint on `user_id`
  - Uses `ON DELETE CASCADE` for automatic cleanup when the associated user is deleted
- **GamePlayer**:
  - Join model between GameSession and Player
  - Tracks player order and game-specific data

## Framework Constraints

### Ruby on Rails
- **Version**: Rails 7.1.3
- **Ruby Version**: 3.2.2
- **Key Decisions**:
  - Uses Rails API mode for JSON-only responses
  - Implements RESTful routing conventions
  - Uses Active Record for database operations
  - Follows Rails conventions for model relationships

### Authentication
  - Uses Devise for user registration and authentication
  - JWT token-based system implemented, including versioning and revocation support
  - Role-based access enforced for admin-only actions
  - Custom controller logic to ensure users have associated Player records before accessing player-specific routes
- **Future Considerations**:
  - OAuth integration possible for third-party auth

### Controllers
- All API routes return data wrapped in a `data: { ... }` JSON structure
- Players must be explicitly created via `/api/players#create` before a user can join or create a GameSession
- User creation does not automatically generate a Player

### Frontend
- **JavaScript Framework**: Stimulus.js
- **Asset Pipeline**: Uses Rails asset pipeline
- **CSS Framework**: Bootstrap
- **Constraints**:
  - No heavy frontend framework (React, Vue, etc.)
  - Server-side rendering for admin interface
  - Minimal JavaScript for game interactions

## API Constraints

### RESTful Design
- Follows REST principles for resource management
- Uses standard HTTP methods (GET, POST, PUT, DELETE)
- Implements resource nesting for related data
- Uses JSON for request/response format

### Rate Limiting
- No rate limiting currently implemented
- Future implementation planned for:
  - API request limits
  - IP-based throttling
  - User-based rate limits

### CORS
- CORS headers not currently configured
- Future implementation needed for:
  - Cross-origin requests
  - Domain whitelisting
  - Preflight request handling

## Game Logic Constraints

### State Management
- Game state stored in JSONB format
- State validation through model callbacks
- No real-time updates (polling required)
- State transitions managed through model methods

### Game Types
- Currently only supports Tic Tac Toe
- Game logic encapsulated in models
- No plugin system for new game types
- Fixed board size and rules

### Player Management
- Maximum 2 players per game
- No spectator support
- No AI players
- No player statistics or history

## Development Constraints

### Testing
- RSpec is now used as the primary testing framework
- Uses DatabaseCleaner with `:transaction` strategy for faster test runs
- Factories managed with FactoryBot and `create_user_with_player!` helper

### Code Style
- Tests are colocated under `spec/`
- Uses `Rubocop` and `Standard` for linting

### Deployment
- No specific deployment platform
- Docker support included
- No cloud provider integration
- No scaling considerations

## Security Constraints

### Authentication
- No authentication required
- No password policies
- No session management
- No role-based access control

### Data Protection
- No encryption for game state
- No data backup strategy
- No data retention policy
- No GDPR compliance measures

### API Security
- No API key authentication
- No request signing
- No input sanitization
- No output encoding

## Performance Constraints

### Scalability
- Single server deployment
- No load balancing
- No caching strategy
- No database sharding

### Real-time Features
- No WebSocket support
- No server-sent events
- Polling-based updates
- No push notifications

### Resource Usage
- No memory limits
- No CPU usage monitoring
- No disk space monitoring
- No network bandwidth limits

## Future Considerations

### Planned Features
1. Authentication system
2. Real-time updates
3. Multiple game types
4. Player statistics
5. AI opponents
6. Spectator mode
7. Tournament support

### Technical Debt
1. Add comprehensive test coverage
2. Implement proper authentication
3. Add real-time capabilities
4. Improve error handling
5. Add monitoring and logging
6. Implement proper security measures
7. Add deployment automation

## Development Guidelines

### Code Organization
- Follow Rails conventions
- Keep controllers thin
- Use service objects for complex logic
- Implement proper error handling

### Testing Requirements
- Write unit tests for models
- Add integration tests for controllers
- Implement system tests for end-to-end flows
- Maintain test coverage above 80%

### Documentation
- Keep API documentation up to date
- Document architectural decisions
- Maintain README with setup instructions
- Add inline code documentation

### Security
- Implement proper authentication
- Add input validation
- Sanitize output
- Follow security best practices 
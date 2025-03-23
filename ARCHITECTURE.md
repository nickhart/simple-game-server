# SimpleGameServer Architecture

This document outlines the architectural decisions and design patterns used in the SimpleGameServer project.

## Overview

SimpleGameServer is built as a Ruby on Rails application that provides a foundation for turn-based games. The architecture focuses on flexibility and extensibility, allowing for various game types to be implemented while maintaining core game session management functionality.

## Core Models

### GameSession

The central model that represents an instance of a game. It manages:

- Player limits (min and max players)
- Game state (waiting, active, finished)
- Turn progression
- Player participation

```ruby
class GameSession
  # Associations
  has_many :game_players
  has_many :players, through: :game_players

  # States
  enum status: { waiting: 0, active: 1, finished: 2 }
```

Key responsibilities:
- Enforcing player limits
- Managing game state transitions
- Coordinating turn progression
- Validating game rules

### Player

Represents a participant in the game system. Features:
- Can participate in multiple games
- Maintains player identity
- Links to game sessions through GamePlayer join model

### GamePlayer (Join Model)

Manages the many-to-many relationship between games and players:
- Tracks player participation in specific games
- Prevents duplicate player entries in the same game
- Handles clean-up when players leave games

## State Management

### Game States

1. **Waiting**
   - Initial state for new games
   - Players can join
   - Game can't start until minimum players reached
   - Default state on creation

2. **Active**
   - Game is in progress
   - Turn management is active
   - No new players can join
   - Player count must be within limits

3. **Finished**
   - Game is complete
   - No further actions allowed
   - Historical record maintained

### Turn Management

Turn progression is handled through:
- `current_player_index` tracking
- Circular player rotation
- Automatic index updates
- Creation timestamp-based player ordering

## Validation Layer

### Game Session Validations

```ruby
validates :min_players, presence: true
validates :max_players, presence: true
validates :min_players, numericality: { greater_than: 0, only_integer: true }
validates :max_players, numericality: { greater_than_or_equal_to: :min_players }
```

Additional custom validations:
- Player count limits
- State transition rules
- Turn progression constraints

## Database Schema

### Core Tables

```sql
create_table "game_sessions" do |t|
  t.integer "status"
  t.integer "min_players"
  t.integer "max_players"
  t.integer "current_player_index"
  t.timestamps
end

create_table "players" do |t|
  t.string "name"
  t.timestamps
end

create_table "game_players" do |t|
  t.references "game_session"
  t.references "player"
  t.timestamps
end
```

## Testing Strategy

The project employs a comprehensive testing approach:

1. **Unit Tests**
   - Model validations
   - Business logic
   - State transitions
   - Turn management

2. **Integration Tests**
   - Player interactions
   - Game flow
   - State changes

3. **Controller Tests**
   - API endpoints
   - Request/response cycles
   - Error handling

## Future Considerations

1. **Scalability**
   - Potential for background job processing
   - Caching strategies for active games
   - Database optimization for large player counts

2. **Feature Extensions**
   - Real-time updates via ActionCable
   - Game type specialization
   - Player authentication/authorization
   - Game history and statistics

3. **API Evolution**
   - Versioning strategy
   - Documentation automation
   - Client SDK development

## Security Considerations

1. **Data Protection**
   - Validation of game state changes
   - Player action authorization
   - Rate limiting for game actions

2. **Access Control**
   - Game session ownership
   - Player verification
   - State transition guards

## Development Guidelines

1. **Code Organization**
   - Follow Rails conventions
   - Keep models focused and single-responsibility
   - Use service objects for complex game logic
   - Maintain comprehensive test coverage

2. **Best Practices**
   - Write descriptive commit messages
   - Document public interfaces
   - Follow Ruby style guide
   - Regular security updates 
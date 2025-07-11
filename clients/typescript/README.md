# Simple Game Server - TypeScript Client

A TypeScript client for the Simple Game Server API, providing both REST API access and real-time WebSocket connectivity for multiplayer games.

## Features

- 🎮 **Complete API Coverage** - All REST endpoints for game management
- ⚡ **Real-time Updates** - WebSocket support for live game state changes
- 🔒 **JWT Authentication** - Secure token-based authentication
- 📝 **Full TypeScript Support** - Complete type definitions and IntelliSense
- 🌐 **Isomorphic** - Works in Node.js and browsers
- 🔄 **Auto-reconnection** - Automatic WebSocket reconnection handling

## Installation

### From npm (when published)
```bash
npm install @simple-game-server/client
```

### From monorepo (local development)
```bash
# In your React/Node.js project
npm install file:../path/to/simple-game-server/clients/typescript

# Or with relative path from your project
npm install ../simple-game-server/clients/typescript
```

## Quick Start

```typescript
import { GameServerClient } from '@simple-game-server/client';

// Initialize client
const client = new GameServerClient({
  apiUrl: 'http://localhost:3000',
});

// Login and setup
const token = await client.login({
  email: 'player@example.com',
  password: 'password'
});

// Create a player
const player = await client.createPlayer({ name: 'Player 1' });

// Find a game
const game = await client.getGameByName('Tic Tac Toe');

// Create or join a game session
const session = await client.createGameSession(game.id);

// Subscribe to real-time updates
client.subscribe(session.id, (updatedSession) => {
  console.log('Game updated:', updatedSession);
});

// Make a move
await client.updateGameSession(game.id, session.id, {
  state: { /* your game state */ }
});
```

## API Reference

### Authentication

```typescript
// Login
const token = await client.login({ email, password });

// Logout
await client.logout();
```

### Player Management

```typescript
// Create player
const player = await client.createPlayer({ name: 'Player Name' });

// Get current player
const player = await client.getCurrentPlayer();
```

### Game Management

```typescript
// Get all games
const games = await client.getGames();

// Get specific game
const game = await client.getGame(gameId);
const game = await client.getGameByName('Game Name');
```

### Game Sessions

```typescript
// Create session
const session = await client.createGameSession(gameId);

// Join session
const session = await client.joinGameSession(gameId, sessionId);

// Start session
const session = await client.startGameSession(gameId, sessionId);

// Update session (make moves)
const session = await client.updateGameSession(gameId, sessionId, {
  state: newGameState
});

// Leave session
await client.leaveGameSession(gameId, sessionId);
```

### Real-time Updates

```typescript
// Subscribe to session updates
client.subscribe(sessionId, (session) => {
  // Handle real-time game state changes
  console.log('Current player:', session.current_player);
  console.log('Game state:', session.state);
});

// Unsubscribe
client.unsubscribe(sessionId);

// Disconnect all WebSockets
client.disconnect();
```

### Event Handling

```typescript
client.on('connected', () => {
  console.log('WebSocket connected');
});

client.on('disconnected', () => {
  console.log('WebSocket disconnected');
});

client.on('error', (error) => {
  console.error('Client error:', error);
});
```

## Error Handling

```typescript
import { GameServerError } from '@simple-game-server/client';

try {
  await client.joinGameSession(gameId, sessionId);
} catch (error) {
  if (error instanceof GameServerError) {
    console.log('Status:', error.statusCode);
    console.log('Message:', error.message);
  }
}
```

## Configuration

```typescript
const client = new GameServerClient({
  apiUrl: 'http://localhost:3000',  // Required
  token: 'existing-jwt-token',      // Optional
  wsUrl: 'ws://localhost:3000/cable' // Optional (auto-derived from apiUrl)
});
```

## React Integration

For React applications, see the comprehensive integration guides:

- **[React Integration Guide](./REACT_INTEGRATION.md)** - Complete patterns and examples
- **[React Hooks](./examples/react-hooks.tsx)** - Copy-paste hooks for your project

### Quick React Example
```tsx
import { useGameClient, useGameSession } from './hooks/gameHooks';

const MyGame = () => {
  const { client, currentPlayer, login } = useGameClient();
  const [sessionId, setSessionId] = useState<number>();
  const { session, makeMove } = useGameSession(client, sessionId);

  // Login, create session, make moves, handle real-time updates
  return <div>Game UI here</div>;
};
```

## Monorepo Development

This client is part of the Simple Game Server monorepo:

```
simple-game-server/
├── server/                 # Rails API server
├── clients/
│   ├── typescript/        # This client
│   ├── dart/              # Dart client  
│   └── ruby/              # Ruby client (in examples/)
└── examples/
    └── tic_tac_toe/       # Ruby CLI example
```

### Using in Same Monorepo
```bash
# From your React app in the monorepo
npm install ../clients/typescript

# Or from outside the monorepo  
npm install file:/path/to/simple-game-server/clients/typescript
```

### Publishing Workflow
```bash
# Build and test
npm run build && npm test

# Publish to npm (when ready)
npm publish --access public
```

## Development

```bash
# Install dependencies
npm install

# Build
npm run build

# Watch mode
npm run dev

# Run tests
npm test

# Lint
npm run lint
```

## Architecture Notes for Claude

This client implements the **hybrid REST + WebSocket pattern**:

- **REST API**: All game actions (login, create/join sessions, make moves)
- **WebSocket**: Real-time state synchronization and event broadcasting
- **Event-driven**: React components subscribe to game session updates
- **Type-safe**: Full TypeScript coverage for game state and API responses

Key integration points:
1. Use `useGameClient()` hook for authentication and client setup
2. Use `useGameSession()` hook for real-time game state management  
3. All game actions return promises and trigger WebSocket broadcasts
4. Handle loading states and errors in React components
5. WebSocket automatically reconnects and resubscribes

## License

MIT
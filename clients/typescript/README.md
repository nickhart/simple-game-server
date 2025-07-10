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

```bash
npm install @simple-game-server/client
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

## License

MIT
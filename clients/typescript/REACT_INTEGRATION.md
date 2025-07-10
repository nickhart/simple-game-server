# React Integration Guide

This guide shows how to integrate the Simple Game Server TypeScript client into React applications for real-time multiplayer games.

## Installation

### From npm (when published)
```bash
npm install @simple-game-server/client
```

### From monorepo (local development)
```bash
# In your React project
npm install file:../path/to/simple-game-server/clients/typescript
```

## Basic React Hook Pattern

```tsx
import { useState, useEffect, useCallback } from 'react';
import { GameServerClient, GameSession } from '@simple-game-server/client';

export const useGameClient = () => {
  const [client] = useState(() => new GameServerClient({
    apiUrl: process.env.REACT_APP_API_URL || 'http://localhost:3000'
  }));
  
  const [isConnected, setIsConnected] = useState(false);
  const [currentPlayer, setCurrentPlayer] = useState(null);

  useEffect(() => {
    client.on('connected', () => setIsConnected(true));
    client.on('disconnected', () => setIsConnected(false));
    
    return () => client.disconnect();
  }, [client]);

  const login = useCallback(async (email: string, password: string) => {
    const token = await client.login({ email, password });
    const player = await client.getCurrentPlayer();
    setCurrentPlayer(player);
    return { token, player };
  }, [client]);

  return { client, isConnected, currentPlayer, login };
};
```

## Game Session Hook

```tsx
import { useState, useEffect, useCallback } from 'react';
import { GameServerClient, GameSession } from '@simple-game-server/client';

export const useGameSession = (client: GameServerClient, sessionId?: number) => {
  const [session, setSession] = useState<GameSession | null>(null);
  const [isSubscribed, setIsSubscribed] = useState(false);

  useEffect(() => {
    if (!sessionId) return;

    // Subscribe to real-time updates
    client.subscribe(sessionId, (updatedSession) => {
      setSession(updatedSession);
    });
    setIsSubscribed(true);

    return () => {
      client.unsubscribe(sessionId);
      setIsSubscribed(false);
    };
  }, [client, sessionId]);

  const makeMove = useCallback(async (gameState: any) => {
    if (!session) return;
    
    const updatedSession = await client.updateGameSession(
      session.game_id,
      session.id,
      { state: gameState }
    );
    
    // Session will also be updated via WebSocket
    return updatedSession;
  }, [client, session]);

  return { session, isSubscribed, makeMove };
};
```

## Complete Connect 4 Example

```tsx
import React, { useState, useEffect } from 'react';
import { useGameClient, useGameSession } from './hooks/gameHooks';

const Connect4Game: React.FC = () => {
  const { client, isConnected, currentPlayer, login } = useGameClient();
  const [sessionId, setSessionId] = useState<number>();
  const { session, makeMove } = useGameSession(client, sessionId);

  // Login flow
  const handleLogin = async () => {
    try {
      await login('player@example.com', 'password');
    } catch (error) {
      console.error('Login failed:', error);
    }
  };

  // Create or join game
  const startGame = async () => {
    try {
      const game = await client.getGameByName('Connect 4');
      const newSession = await client.createGameSession(game.id);
      setSessionId(newSession.id);
    } catch (error) {
      console.error('Failed to start game:', error);
    }
  };

  // Handle player move
  const handleColumnClick = async (column: number) => {
    if (!session || session.current_player?.id !== currentPlayer?.id) return;

    const newBoard = [...(session.state.board || [])];
    // Add Connect 4 logic here
    
    try {
      await makeMove({ board: newBoard });
    } catch (error) {
      console.error('Move failed:', error);
    }
  };

  if (!currentPlayer) {
    return (
      <div>
        <button onClick={handleLogin}>Login</button>
      </div>
    );
  }

  if (!session) {
    return (
      <div>
        <button onClick={startGame}>Start Connect 4 Game</button>
      </div>
    );
  }

  return (
    <div className="connect4-game">
      <div className="game-status">
        Status: {session.status} | 
        Current Player: {session.current_player?.name} |
        WebSocket: {isConnected ? '🟢' : '🔴'}
      </div>
      
      <div className="game-board">
        {/* Render Connect 4 board based on session.state.board */}
        {Array.from({ length: 7 }, (_, col) => (
          <button
            key={col}
            onClick={() => handleColumnClick(col)}
            disabled={session.current_player?.id !== currentPlayer?.id}
          >
            Drop in Column {col + 1}
          </button>
        ))}
      </div>

      {session.status === 'finished' && (
        <div className="game-over">
          {session.winner_index !== null 
            ? `Player ${session.players[session.winner_index].name} wins!`
            : "It's a draw!"
          }
        </div>
      )}
    </div>
  );
};

export default Connect4Game;
```

## Context Provider Pattern

For larger applications, use React Context:

```tsx
import React, { createContext, useContext, ReactNode } from 'react';
import { GameServerClient } from '@simple-game-server/client';

const GameClientContext = createContext<GameServerClient | null>(null);

export const GameClientProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const client = new GameServerClient({
    apiUrl: process.env.REACT_APP_API_URL || 'http://localhost:3000'
  });

  return (
    <GameClientContext.Provider value={client}>
      {children}
    </GameClientContext.Provider>
  );
};

export const useGameClientContext = () => {
  const client = useContext(GameClientContext);
  if (!client) {
    throw new Error('useGameClientContext must be used within GameClientProvider');
  }
  return client;
};
```

## Environment Configuration

Create `.env` file in your React project:

```bash
# Simple Game Server API
REACT_APP_API_URL=http://localhost:3000
REACT_APP_WS_URL=ws://localhost:3000/cable

# Optional: Override WebSocket URL
# REACT_APP_WS_URL=ws://localhost:3000/custom-ws
```

## TypeScript Types

The client exports all necessary types:

```tsx
import type {
  GameSession,
  Player,
  Game,
  GameServerError,
  WebSocketMessage
} from '@simple-game-server/client';

// Use types in your React components
interface GameProps {
  session: GameSession;
  currentPlayer: Player;
}
```

## Error Handling

```tsx
import { GameServerError } from '@simple-game-server/client';

const handleApiCall = async () => {
  try {
    await client.joinGameSession(gameId, sessionId);
  } catch (error) {
    if (error instanceof GameServerError) {
      // Handle specific API errors
      console.log('API Error:', error.message, 'Status:', error.statusCode);
    } else {
      // Handle network/other errors
      console.error('Unexpected error:', error);
    }
  }
};
```

## Best Practices

1. **Single Client Instance**: Create one client instance per app
2. **Cleanup WebSockets**: Always unsubscribe in useEffect cleanup
3. **Error Boundaries**: Wrap game components in error boundaries
4. **Loading States**: Handle loading/connecting states in UI
5. **Optimistic Updates**: Update UI immediately, sync with server
6. **Reconnection**: Handle WebSocket reconnection gracefully

## Testing

Mock the client for testing:

```tsx
// __mocks__/@simple-game-server/client.ts
export const GameServerClient = jest.fn().mockImplementation(() => ({
  login: jest.fn(),
  getCurrentPlayer: jest.fn(),
  createGameSession: jest.fn(),
  subscribe: jest.fn(),
  unsubscribe: jest.fn(),
  on: jest.fn(),
  disconnect: jest.fn(),
}));
```

This integration pattern provides a solid foundation for any real-time multiplayer game built with React and the Simple Game Server.
/**
 * React Hooks for Simple Game Server Integration
 * 
 * Copy these hooks into your React project to get started quickly.
 * Customize as needed for your specific game requirements.
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import { GameServerClient, GameSession, Player, Game, GameServerError } from '../src/index';

// Main client hook - use once per app
export const useGameClient = (apiUrl: string = 'http://localhost:3000') => {
  const [client] = useState(() => new GameServerClient({ apiUrl }));
  const [isConnected, setIsConnected] = useState(false);
  const [currentPlayer, setCurrentPlayer] = useState<Player | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    // WebSocket connection events
    client.on('connected', () => setIsConnected(true));
    client.on('disconnected', () => setIsConnected(false));
    client.on('error', (error: GameServerError) => {
      console.error('Game client error:', error);
    });

    return () => {
      client.disconnect();
    };
  }, [client]);

  const login = useCallback(async (email: string, password: string) => {
    try {
      const token = await client.login({ email, password });
      const player = await client.getCurrentPlayer();
      setCurrentPlayer(player);
      setIsAuthenticated(true);
      return { token, player };
    } catch (error) {
      setIsAuthenticated(false);
      throw error;
    }
  }, [client]);

  const logout = useCallback(async () => {
    try {
      await client.logout();
      setCurrentPlayer(null);
      setIsAuthenticated(false);
    } catch (error) {
      console.error('Logout error:', error);
    }
  }, [client]);

  const createPlayer = useCallback(async (name: string) => {
    try {
      const player = await client.createPlayer({ name });
      setCurrentPlayer(player);
      return player;
    } catch (error) {
      throw error;
    }
  }, [client]);

  return {
    client,
    isConnected,
    currentPlayer,
    isAuthenticated,
    login,
    logout,
    createPlayer
  };
};

// Game session hook - handles real-time game state
export const useGameSession = (client: GameServerClient, sessionId?: number) => {
  const [session, setSession] = useState<GameSession | null>(null);
  const [isSubscribed, setIsSubscribed] = useState(false);
  const [loading, setLoading] = useState(false);
  const sessionRef = useRef<GameSession | null>(null);

  // Keep ref in sync for stable access in callbacks
  useEffect(() => {
    sessionRef.current = session;
  }, [session]);

  // Subscribe to real-time updates
  useEffect(() => {
    if (!sessionId) {
      setSession(null);
      setIsSubscribed(false);
      return;
    }

    setLoading(true);

    // Load initial session data
    client.getGameSession(sessionRef.current?.game_id || 1, sessionId)
      .then(setSession)
      .catch(console.error)
      .finally(() => setLoading(false));

    // Subscribe to real-time updates
    client.subscribe(sessionId, (updatedSession: GameSession) => {
      setSession(updatedSession);
    });
    setIsSubscribed(true);

    return () => {
      client.unsubscribe(sessionId);
      setIsSubscribed(false);
    };
  }, [client, sessionId]);

  const makeMove = useCallback(async (gameState: any, additionalData?: any) => {
    if (!sessionRef.current) throw new Error('No active session');
    
    setLoading(true);
    try {
      const updatedSession = await client.updateGameSession(
        sessionRef.current.game_id,
        sessionRef.current.id,
        { 
          state: gameState,
          ...additionalData
        }
      );
      
      // Real-time update will come via WebSocket, but return for immediate use
      return updatedSession;
    } finally {
      setLoading(false);
    }
  }, [client]);

  const startSession = useCallback(async () => {
    if (!sessionRef.current) throw new Error('No active session');
    
    setLoading(true);
    try {
      const updatedSession = await client.startGameSession(
        sessionRef.current.game_id,
        sessionRef.current.id
      );
      return updatedSession;
    } finally {
      setLoading(false);
    }
  }, [client]);

  const leaveSession = useCallback(async () => {
    if (!sessionRef.current) throw new Error('No active session');
    
    setLoading(true);
    try {
      await client.leaveGameSession(
        sessionRef.current.game_id,
        sessionRef.current.id
      );
      setSession(null);
    } finally {
      setLoading(false);
    }
  }, [client]);

  return {
    session,
    isSubscribed,
    loading,
    makeMove,
    startSession,
    leaveSession
  };
};

// Game management hook
export const useGames = (client: GameServerClient) => {
  const [games, setGames] = useState<Game[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedGame, setSelectedGame] = useState<Game | null>(null);

  const loadGames = useCallback(async () => {
    setLoading(true);
    try {
      const gamesList = await client.getGames();
      setGames(gamesList);
    } catch (error) {
      console.error('Failed to load games:', error);
    } finally {
      setLoading(false);
    }
  }, [client]);

  const selectGameByName = useCallback(async (gameName: string) => {
    try {
      const game = await client.getGameByName(gameName);
      setSelectedGame(game);
      return game;
    } catch (error) {
      console.error('Failed to select game:', error);
      throw error;
    }
  }, [client]);

  const createGameSession = useCallback(async (gameId?: number) => {
    const targetGameId = gameId || selectedGame?.id;
    if (!targetGameId) throw new Error('No game selected');

    try {
      const session = await client.createGameSession(targetGameId);
      return session;
    } catch (error) {
      console.error('Failed to create session:', error);
      throw error;
    }
  }, [client, selectedGame]);

  const joinGameSession = useCallback(async (gameId: number, sessionId: number) => {
    try {
      const session = await client.joinGameSession(gameId, sessionId);
      return session;
    } catch (error) {
      console.error('Failed to join session:', error);
      throw error;
    }
  }, [client]);

  const getGameSessions = useCallback(async (gameId?: number) => {
    const targetGameId = gameId || selectedGame?.id;
    if (!targetGameId) throw new Error('No game selected');

    try {
      const sessions = await client.getGameSessions(targetGameId);
      return sessions;
    } catch (error) {
      console.error('Failed to get sessions:', error);
      throw error;
    }
  }, [client, selectedGame]);

  // Load games on mount
  useEffect(() => {
    loadGames();
  }, [loadGames]);

  return {
    games,
    loading,
    selectedGame,
    loadGames,
    selectGameByName,
    createGameSession,
    joinGameSession,
    getGameSessions
  };
};

// Utility hook for game state helpers
export const useGameHelpers = () => {
  const isMyTurn = useCallback((session: GameSession | null, currentPlayer: Player | null) => {
    if (!session || !currentPlayer) return false;
    return session.current_player?.id === currentPlayer.id;
  }, []);

  const getPlayerIndex = useCallback((session: GameSession | null, player: Player | null) => {
    if (!session || !player) return -1;
    return session.players.findIndex(p => p.id === player.id);
  }, []);

  const isGameOver = useCallback((session: GameSession | null) => {
    return session?.status === 'finished';
  }, []);

  const getWinner = useCallback((session: GameSession | null) => {
    if (!session || session.winner_index === null) return null;
    return session.players[session.winner_index] || null;
  }, []);

  const formatGameStatus = useCallback((session: GameSession | null, currentPlayer: Player | null) => {
    if (!session) return 'No game';
    
    switch (session.status) {
      case 'waiting':
        return `Waiting for players (${session.players.length}/${session.game.max_players})`;
      case 'active':
        if (isMyTurn(session, currentPlayer)) {
          return "It's your turn!";
        }
        return `Waiting for ${session.current_player?.name || 'opponent'}`;
      case 'finished':
        const winner = getWinner(session);
        if (winner) {
          return winner.id === currentPlayer?.id ? 'You won!' : `${winner.name} won!`;
        }
        return "It's a draw!";
      default:
        return session.status;
    }
  }, [isMyTurn, getWinner]);

  return {
    isMyTurn,
    getPlayerIndex,
    isGameOver,
    getWinner,
    formatGameStatus
  };
};

// Example usage in a component:
/*
const MyGameComponent = () => {
  const { client, currentPlayer, login } = useGameClient();
  const { selectedGame, createGameSession, selectGameByName } = useGames(client);
  const [sessionId, setSessionId] = useState<number>();
  const { session, makeMove } = useGameSession(client, sessionId);
  const { isMyTurn, formatGameStatus } = useGameHelpers();

  const handleStartGame = async () => {
    await selectGameByName('Connect 4');
    const newSession = await createGameSession();
    setSessionId(newSession.id);
  };

  return (
    <div>
      <div>Status: {formatGameStatus(session, currentPlayer)}</div>
      <div>My Turn: {isMyTurn(session, currentPlayer) ? 'Yes' : 'No'}</div>
      {!session && <button onClick={handleStartGame}>Start Game</button>}
    </div>
  );
};
*/
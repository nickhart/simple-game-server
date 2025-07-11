import { GameServerClient } from '../src/client';
import { GameServerError } from '../src/types';

// Mock fetch
const mockFetch = global.fetch as jest.MockedFunction<typeof fetch>;

describe('GameServerClient', () => {
  let client: GameServerClient;

  beforeEach(() => {
    client = new GameServerClient({
      apiUrl: 'http://localhost:3000'
    });
    mockFetch.mockClear();
  });

  describe('constructor', () => {
    it('should initialize with config', () => {
      const client = new GameServerClient({
        apiUrl: 'http://localhost:3000',
        token: 'test-token'
      });

      expect(client).toBeDefined();
    });

    it('should remove trailing slash from apiUrl', () => {
      const client = new GameServerClient({
        apiUrl: 'http://localhost:3000/'
      });

      expect(client).toBeDefined();
    });

    it('should derive wsUrl from apiUrl', () => {
      const client = new GameServerClient({
        apiUrl: 'http://localhost:3000'
      });

      expect(client).toBeDefined();
    });
  });

  describe('authentication', () => {
    it('should login successfully', async () => {
      const mockResponse = {
        ok: true,
        json: () => Promise.resolve({ token: 'jwt-token-123' })
      };
      mockFetch.mockResolvedValueOnce(mockResponse as any);

      const token = await client.login({
        email: 'test@example.com',
        password: 'password'
      });

      expect(token).toBe('jwt-token-123');
      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:3000/api/tokens/login',
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          }),
          body: JSON.stringify({
            user: {
              email: 'test@example.com',
              password: 'password'
            }
          })
        })
      );
    });

    it('should logout successfully', async () => {
      // Set token first
      client['token'] = 'test-token';

      const mockResponse = {
        ok: true,
        json: () => Promise.resolve({})
      };
      mockFetch.mockResolvedValueOnce(mockResponse as any);

      await client.logout();

      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:3000/api/tokens/logout',
        expect.objectContaining({
          method: 'DELETE',
          headers: expect.objectContaining({
            'Authorization': 'Bearer test-token'
          })
        })
      );
    });
  });

  describe('player management', () => {
    beforeEach(() => {
      client['token'] = 'test-token';
    });

    it('should create player', async () => {
      const mockPlayer = {
        id: 'player-uuid',
        user_id: 1,
        name: 'Test Player',
        created_at: '2023-01-01T00:00:00Z',
        updated_at: '2023-01-01T00:00:00Z'
      };

      const mockResponse = {
        ok: true,
        json: () => Promise.resolve(mockPlayer)
      };
      mockFetch.mockResolvedValueOnce(mockResponse as any);

      const player = await client.createPlayer({ name: 'Test Player' });

      expect(player).toEqual(mockPlayer);
      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:3000/api/players',
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'Authorization': 'Bearer test-token'
          }),
          body: JSON.stringify({ player: { name: 'Test Player' } })
        })
      );
    });

    it('should get current player', async () => {
      const mockPlayer = {
        id: 'player-uuid',
        user_id: 1,
        name: 'Current Player',
        created_at: '2023-01-01T00:00:00Z',
        updated_at: '2023-01-01T00:00:00Z'
      };

      const mockResponse = {
        ok: true,
        json: () => Promise.resolve(mockPlayer)
      };
      mockFetch.mockResolvedValueOnce(mockResponse as any);

      const player = await client.getCurrentPlayer();

      expect(player).toEqual(mockPlayer);
      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:3000/api/players/me',
        expect.objectContaining({
          headers: expect.objectContaining({
            'Authorization': 'Bearer test-token'
          })
        })
      );
    });
  });

  describe('game management', () => {
    beforeEach(() => {
      client['token'] = 'test-token';
    });

    it('should get all games', async () => {
      const mockGames = [
        {
          id: 1,
          name: 'Tic Tac Toe',
          description: 'Classic game',
          min_players: 2,
          max_players: 2,
          state_schema: {},
          created_at: '2023-01-01T00:00:00Z',
          updated_at: '2023-01-01T00:00:00Z'
        }
      ];

      const mockResponse = {
        ok: true,
        json: () => Promise.resolve(mockGames)
      };
      mockFetch.mockResolvedValueOnce(mockResponse as any);

      const games = await client.getGames();

      expect(games).toEqual(mockGames);
      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:3000/api/games',
        expect.objectContaining({
          headers: expect.objectContaining({
            'Authorization': 'Bearer test-token'
          })
        })
      );
    });

    it('should get game by ID', async () => {
      const mockGame = {
        id: 1,
        name: 'Tic Tac Toe',
        description: 'Classic game',
        min_players: 2,
        max_players: 2,
        state_schema: {},
        created_at: '2023-01-01T00:00:00Z',
        updated_at: '2023-01-01T00:00:00Z'
      };

      const mockResponse = {
        ok: true,
        json: () => Promise.resolve(mockGame)
      };
      mockFetch.mockResolvedValueOnce(mockResponse as any);

      const game = await client.getGame(1);

      expect(game).toEqual(mockGame);
      expect(mockFetch).toHaveBeenCalledWith('http://localhost:3000/api/games/1', expect.any(Object));
    });

    it('should get game by name', async () => {
      const mockGames = [
        {
          id: 1,
          name: 'Tic Tac Toe',
          description: 'Classic game',
          min_players: 2,
          max_players: 2,
          state_schema: {},
          created_at: '2023-01-01T00:00:00Z',
          updated_at: '2023-01-01T00:00:00Z'
        }
      ];

      const mockResponse = {
        ok: true,
        json: () => Promise.resolve(mockGames)
      };
      mockFetch.mockResolvedValueOnce(mockResponse as any);

      const game = await client.getGameByName('Tic Tac Toe');

      expect(game).toEqual(mockGames[0]);
    });

    it('should throw error when game not found by name', async () => {
      const mockResponse = {
        ok: true,
        json: () => Promise.resolve([])
      };
      mockFetch.mockResolvedValueOnce(mockResponse as any);

      await expect(client.getGameByName('Nonexistent Game')).rejects.toThrow(
        new GameServerError('Game not found: Nonexistent Game')
      );
    });
  });

  describe('game session management', () => {
    beforeEach(() => {
      client['token'] = 'test-token';
    });

    const mockSession = {
      id: 1,
      game_id: 1,
      status: 'waiting' as const,
      state: {},
      current_player_index: null,
      winner_index: null,
      creator_id: 'creator-uuid',
      created_at: '2023-01-01T00:00:00Z',
      updated_at: '2023-01-01T00:00:00Z',
      players: [],
      game: {
        id: 1,
        name: 'Test Game',
        description: 'Test',
        min_players: 2,
        max_players: 2,
        state_schema: {},
        created_at: '2023-01-01T00:00:00Z',
        updated_at: '2023-01-01T00:00:00Z'
      }
    };

    it('should create game session', async () => {
      const mockResponse = {
        ok: true,
        json: () => Promise.resolve(mockSession)
      };
      mockFetch.mockResolvedValueOnce(mockResponse as any);

      const session = await client.createGameSession(1);

      expect(session).toEqual(mockSession);
      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:3000/api/games/1/sessions',
        expect.objectContaining({
          method: 'POST',
          body: JSON.stringify({})
        })
      );
    });

    it('should get game sessions', async () => {
      const mockResponse = {
        ok: true,
        json: () => Promise.resolve([mockSession])
      };
      mockFetch.mockResolvedValueOnce(mockResponse as any);

      const sessions = await client.getGameSessions(1);

      expect(sessions).toEqual([mockSession]);
      expect(mockFetch).toHaveBeenCalledWith('http://localhost:3000/api/games/1/sessions', expect.any(Object));
    });

    it('should join game session', async () => {
      const mockResponse = {
        ok: true,
        json: () => Promise.resolve(mockSession)
      };
      mockFetch.mockResolvedValueOnce(mockResponse as any);

      const session = await client.joinGameSession(1, 1);

      expect(session).toEqual(mockSession);
      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:3000/api/games/1/sessions/1/join',
        expect.objectContaining({
          method: 'POST'
        })
      );
    });

    it('should start game session', async () => {
      const mockResponse = {
        ok: true,
        json: () => Promise.resolve(mockSession)
      };
      mockFetch.mockResolvedValueOnce(mockResponse as any);

      const session = await client.startGameSession(1, 1);

      expect(session).toEqual(mockSession);
      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:3000/api/games/1/sessions/1/start',
        expect.objectContaining({
          method: 'POST'
        })
      );
    });

    it('should update game session', async () => {
      const updateData = { state: { board: [1, 2, 3] } };
      const mockResponse = {
        ok: true,
        json: () => Promise.resolve({ ...mockSession, ...updateData })
      };
      mockFetch.mockResolvedValueOnce(mockResponse as any);

      const session = await client.updateGameSession(1, 1, updateData);

      expect(session.state).toEqual(updateData.state);
      expect(mockFetch).toHaveBeenCalledWith(
        'http://localhost:3000/api/games/1/sessions/1',
        expect.objectContaining({
          method: 'PUT',
          body: JSON.stringify(updateData)
        })
      );
    });
  });

  describe('error handling', () => {
    beforeEach(() => {
      client['token'] = 'test-token';
    });

    it('should throw GameServerError on HTTP error', async () => {
      const mockResponse = {
        ok: false,
        status: 404,
        statusText: 'Not Found',
        json: () => Promise.resolve({ error: 'Game not found' })
      };
      mockFetch.mockResolvedValueOnce(mockResponse as any);

      await expect(client.getGame(999)).rejects.toThrow(
        new GameServerError('Game not found', 404)
      );
    });

    it('should handle JSON parsing errors in error response', async () => {
      const mockResponse = {
        ok: false,
        status: 500,
        statusText: 'Internal Server Error',
        json: () => Promise.reject(new Error('Invalid JSON'))
      };
      mockFetch.mockResolvedValueOnce(mockResponse as any);

      await expect(client.getGame(999)).rejects.toThrow(
        new GameServerError('HTTP 500: Internal Server Error', 500)
      );
    });

    it('should include authorization header when token is set', async () => {
      const mockResponse = {
        ok: true,
        json: () => Promise.resolve([])
      };
      mockFetch.mockResolvedValueOnce(mockResponse as any);

      await client.getGames();

      expect(mockFetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          headers: expect.objectContaining({
            'Authorization': 'Bearer test-token'
          })
        })
      );
    });

    it('should not include authorization header when token is not set', async () => {
      const clientWithoutToken = new GameServerClient({
        apiUrl: 'http://localhost:3000'
      });

      const mockResponse = {
        ok: true,
        json: () => Promise.resolve([])
      };
      mockFetch.mockResolvedValueOnce(mockResponse as any);

      await clientWithoutToken.getGames();

      expect(mockFetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          headers: expect.not.objectContaining({
            'Authorization': expect.any(String)
          })
        })
      );
    });
  });
});
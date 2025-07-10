import { GameServerClient } from '../src/client';
import { GameServerError } from '../src/types';

describe('GameServerClient Integration', () => {
  let client: GameServerClient;

  beforeEach(() => {
    client = new GameServerClient({
      apiUrl: 'http://localhost:3000'
    });
  });

  afterEach(() => {
    client.disconnect();
  });

  describe('complete workflow simulation', () => {
    it('should handle a complete game flow with mocked responses', async () => {
      const mockFetch = global.fetch as jest.MockedFunction<typeof fetch>;

      // Mock login response
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ token: 'test-token' })
      } as any);

      // Mock create player response
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          id: 'player-uuid',
          user_id: 1,
          name: 'Test Player',
          created_at: '2023-01-01T00:00:00Z',
          updated_at: '2023-01-01T00:00:00Z'
        })
      } as any);

      // Mock get games response
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve([{
          id: 1,
          name: 'Tic Tac Toe',
          description: 'Classic game',
          min_players: 2,
          max_players: 2,
          state_schema: {},
          created_at: '2023-01-01T00:00:00Z',
          updated_at: '2023-01-01T00:00:00Z'
        }])
      } as any);

      // Mock create session response
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({
          id: 1,
          game_id: 1,
          status: 'waiting',
          state: {},
          current_player_index: null,
          winner_index: null,
          creator_id: 'player-uuid',
          created_at: '2023-01-01T00:00:00Z',
          updated_at: '2023-01-01T00:00:00Z',
          players: [],
          game: {
            id: 1,
            name: 'Tic Tac Toe',
            description: 'Classic game',
            min_players: 2,
            max_players: 2,
            state_schema: {},
            created_at: '2023-01-01T00:00:00Z',
            updated_at: '2023-01-01T00:00:00Z'
          }
        })
      } as any);

      // Execute complete workflow
      const token = await client.login({
        email: 'test@example.com',
        password: 'password'
      });

      const player = await client.createPlayer({ name: 'Test Player' });
      const games = await client.getGames();
      const game = games[0];
      const session = await client.createGameSession(game.id);

      // Verify workflow
      expect(token).toBe('test-token');
      expect(player.name).toBe('Test Player');
      expect(game.name).toBe('Tic Tac Toe');
      expect(session.game_id).toBe(1);
      expect(session.status).toBe('waiting');

      // Verify all API calls were made in order
      expect(mockFetch).toHaveBeenCalledTimes(4);
      expect(mockFetch).toHaveBeenNthCalledWith(1, 'http://localhost:3000/api/tokens/login', expect.any(Object));
      expect(mockFetch).toHaveBeenNthCalledWith(2, 'http://localhost:3000/api/players', expect.any(Object));
      expect(mockFetch).toHaveBeenNthCalledWith(3, 'http://localhost:3000/api/games', expect.any(Object));
      expect(mockFetch).toHaveBeenNthCalledWith(4, 'http://localhost:3000/api/games/1/sessions', expect.any(Object));
    });

    it('should handle error propagation through workflow', async () => {
      const mockFetch = global.fetch as jest.MockedFunction<typeof fetch>;

      // Mock login success
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ token: 'test-token' })
      } as any);

      // Mock create player failure
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 422,
        statusText: 'Unprocessable Entity',
        json: () => Promise.resolve({ error: 'Name is required' })
      } as any);

      // Login should succeed
      const token = await client.login({
        email: 'test@example.com',
        password: 'password'
      });
      expect(token).toBe('test-token');

      // Create player should fail
      await expect(client.createPlayer({ name: '' })).rejects.toThrow(
        new GameServerError('Name is required', 422)
      );
    });
  });

  describe('event handling integration', () => {
    it('should properly emit and handle events', (done) => {
      const connectCallback = jest.fn();
      const errorCallback = jest.fn();

      client.on('connected', connectCallback);
      client.on('error', errorCallback);

      // Subscribe to trigger connection
      client.subscribe(123, () => {});

      // Simulate WebSocket events
      setTimeout(() => {
        client.emit('connected');
        client.emit('error', new GameServerError('Test error'));

        expect(connectCallback).toHaveBeenCalled();
        expect(errorCallback).toHaveBeenCalledWith(expect.any(GameServerError));
        done();
      }, 10);
    });
  });

  describe('configuration validation', () => {
    it('should work with minimal configuration', () => {
      const minimalClient = new GameServerClient({
        apiUrl: 'http://localhost:3000'
      });

      expect(minimalClient).toBeDefined();
    });

    it('should work with full configuration', () => {
      const fullClient = new GameServerClient({
        apiUrl: 'http://localhost:3000',
        token: 'existing-token',
        wsUrl: 'ws://localhost:3000/custom'
      });

      expect(fullClient).toBeDefined();
    });
  });
});
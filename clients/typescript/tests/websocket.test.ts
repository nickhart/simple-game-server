import { GameServerClient } from '../src/client';
import { GameServerError } from '../src/types';

// Mock WebSocket - use the same mock from setup
const MockWebSocket = require('ws');

describe('GameServerClient WebSocket', () => {
  let client: GameServerClient;
  let mockWs: any;

  beforeEach(() => {
    client = new GameServerClient({
      apiUrl: 'http://localhost:3000'
    });
    
    // Reset WebSocket mock
    MockWebSocket.mockClear();
    mockWs = {
      readyState: 1, // OPEN
      send: jest.fn(),
      close: jest.fn(),
      on: jest.fn(),
      addEventListener: jest.fn(),
      removeEventListener: jest.fn(),
    };
    MockWebSocket.mockReturnValue(mockWs);
  });

  describe('subscription management', () => {
    it('should create WebSocket connection on first subscription', () => {
      const callback = jest.fn();
      
      client.subscribe(123, callback);

      expect(MockWebSocket).toHaveBeenCalledWith('ws://localhost:3000/cable');
      expect(mockWs.on).toHaveBeenCalledWith('open', expect.any(Function));
      expect(mockWs.on).toHaveBeenCalledWith('message', expect.any(Function));
      expect(mockWs.on).toHaveBeenCalledWith('close', expect.any(Function));
      expect(mockWs.on).toHaveBeenCalledWith('error', expect.any(Function));
    });

    it('should reuse existing WebSocket connection', () => {
      const callback1 = jest.fn();
      const callback2 = jest.fn();
      
      client.subscribe(123, callback1);
      client.subscribe(456, callback2);

      expect(MockWebSocket).toHaveBeenCalledTimes(1);
    });

    it('should send subscription message when WebSocket is open', () => {
      const callback = jest.fn();
      
      client.subscribe(123, callback);

      expect(mockWs.send).toHaveBeenCalledWith(JSON.stringify({
        command: 'subscribe',
        identifier: JSON.stringify({
          channel: 'GameSessionChannel',
          id: 123
        })
      }));
    });

    it('should handle WebSocket open event', () => {
      const callback = jest.fn();
      client.subscribe(123, callback);

      // Get the open handler and call it
      const openHandler = mockWs.on.mock.calls.find((call: any) => call[0] === 'open')[1];
      openHandler();

      // Should emit connected event
      const emitSpy = jest.spyOn(client, 'emit');
      openHandler();
      expect(emitSpy).toHaveBeenCalledWith('connected');
    });

    it('should handle WebSocket message event', () => {
      const callback = jest.fn();
      client.subscribe(123, callback);

      const mockSession = {
        id: 123,
        game_id: 1,
        status: 'active',
        state: { board: [1, 2, 3] },
        current_player_index: 0,
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

      const message = {
        event: 'updated',
        data: mockSession
      };

      // Get the message handler and call it
      const messageHandler = mockWs.on.mock.calls.find((call: any) => call[0] === 'message')[1];
      messageHandler(JSON.stringify(message));

      expect(callback).toHaveBeenCalledWith(mockSession);
    });

    it('should handle invalid JSON in WebSocket message', () => {
      const callback = jest.fn();
      client.subscribe(123, callback);

      const errorSpy = jest.spyOn(client, 'emit');

      // Add error listener to prevent unhandled error
      client.on('error', () => {});

      // Get the message handler and call it with invalid JSON
      const messageHandler = mockWs.on.mock.calls.find((call: any) => call[0] === 'message')[1];
      messageHandler('invalid json');

      expect(errorSpy).toHaveBeenCalledWith('error', expect.any(GameServerError));
      expect(callback).not.toHaveBeenCalled();
    });

    it('should handle WebSocket close event', () => {
      const callback = jest.fn();
      client.subscribe(123, callback);

      // Mock setTimeout
      const originalSetTimeout = global.setTimeout;
      global.setTimeout = jest.fn() as any;

      const emitSpy = jest.spyOn(client, 'emit');

      // Get the close handler and call it
      const closeHandler = mockWs.on.mock.calls.find((call: any) => call[0] === 'close')[1];
      closeHandler();

      expect(emitSpy).toHaveBeenCalledWith('disconnected');
      expect(global.setTimeout).toHaveBeenCalledWith(expect.any(Function), 3000);

      // Restore setTimeout
      global.setTimeout = originalSetTimeout;
    });

    it('should handle WebSocket error event', () => {
      const callback = jest.fn();
      client.subscribe(123, callback);

      const emitSpy = jest.spyOn(client, 'emit');
      const testError = new Error('Connection failed');

      // Add error listener to prevent unhandled error
      client.on('error', () => {});

      // Get the error handler and call it
      const errorHandler = mockWs.on.mock.calls.find((call: any) => call[0] === 'error')[1];
      errorHandler(testError);

      expect(emitSpy).toHaveBeenCalledWith('error', expect.any(GameServerError));
    });

    it('should unsubscribe from session updates', () => {
      const callback = jest.fn();
      client.subscribe(123, callback);
      client.unsubscribe(123);

      // Should remove listeners
      const removeAllListenersSpy = jest.spyOn(client, 'removeAllListeners');
      client.unsubscribe(123);
      expect(removeAllListenersSpy).toHaveBeenCalledWith('session:123');
    });

    it('should send subscription on reconnect', () => {
      const callback = jest.fn();
      client.subscribe(123, callback);

      // Clear previous sends
      mockWs.send.mockClear();

      // Simulate reconnection
      const openHandler = mockWs.on.mock.calls.find((call: any) => call[0] === 'open')[1];
      openHandler();

      expect(mockWs.send).toHaveBeenCalledWith(JSON.stringify({
        command: 'subscribe',
        identifier: JSON.stringify({
          channel: 'GameSessionChannel',
          id: 123
        })
      }));
    });
  });

  describe('disconnect', () => {
    it('should close WebSocket connection', () => {
      const callback = jest.fn();
      client.subscribe(123, callback);
      
      client.disconnect();

      expect(mockWs.close).toHaveBeenCalled();
    });

    it('should clear all subscriptions', () => {
      const callback1 = jest.fn();
      const callback2 = jest.fn();
      client.subscribe(123, callback1);
      client.subscribe(456, callback2);

      const removeAllListenersSpy = jest.spyOn(client, 'removeAllListeners');
      
      client.disconnect();

      expect(removeAllListenersSpy).toHaveBeenCalled();
    });

    it('should handle disconnect when no WebSocket exists', () => {
      expect(() => client.disconnect()).not.toThrow();
    });
  });

  describe('custom WebSocket URL', () => {
    it('should use custom WebSocket URL when provided', () => {
      const clientWithCustomWs = new GameServerClient({
        apiUrl: 'http://localhost:3000',
        wsUrl: 'ws://custom:8080/ws'
      });

      const callback = jest.fn();
      clientWithCustomWs.subscribe(123, callback);

      expect(MockWebSocket).toHaveBeenCalledWith('ws://custom:8080/ws');
    });
  });

  describe('WebSocket state management', () => {
    it('should not send subscription when WebSocket is not open', () => {
      // Mock WebSocket as connecting
      mockWs.readyState = 0; // CONNECTING
      
      const callback = jest.fn();
      client.subscribe(123, callback);

      // Should not send subscription message immediately
      expect(mockWs.send).not.toHaveBeenCalled();
    });

    it('should handle multiple subscriptions to same session', () => {
      const callback1 = jest.fn();
      const callback2 = jest.fn();
      
      client.subscribe(123, callback1);
      client.subscribe(123, callback2);

      const mockSession = {
        id: 123,
        game_id: 1,
        status: 'active' as const,
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

      const message = { event: 'updated', data: mockSession };
      const messageHandler = mockWs.on.mock.calls.find((call: any) => call[0] === 'message')[1];
      messageHandler(JSON.stringify(message));

      expect(callback1).toHaveBeenCalledWith(mockSession);
      expect(callback2).toHaveBeenCalledWith(mockSession);
    });
  });
});
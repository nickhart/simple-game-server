import { EventEmitter } from 'events';
import WebSocket from 'ws';
import {
  ClientConfig,
  ApiResponse,
  User,
  Player,
  Game,
  GameSession,
  LoginRequest,
  CreatePlayerRequest,
  CreateGameSessionRequest,
  JoinGameSessionRequest,
  UpdateGameSessionRequest,
  CreateUserRequest,
  UpdateUserRequest,
  CreateGameRequest,
  GameSessionUpdateMessage,
  GameServerError,
} from './types';

export class GameServerClient extends EventEmitter {
  private apiUrl: string;
  private wsUrl: string;
  private token?: string;
  private ws?: WebSocket;
  private subscriptions = new Set<number>();

  constructor(config: ClientConfig) {
    super();
    this.apiUrl = config.apiUrl.replace(/\/$/, ''); // Remove trailing slash
    this.wsUrl = config.wsUrl || this.apiUrl.replace(/^http/, 'ws') + '/cable';
    this.token = config.token;
    // console.log('🔑 GameServerClient constructor - token:', this.token);
  }

  // Expose token for debugging
  get authToken(): string | undefined {
    return this.token;
  }

  // Authentication
  async login(credentials: LoginRequest): Promise<string> {
    const response = await this.request<{ data: { access_token: string } }>('/api/tokens/login', {
      method: 'POST',
      body: JSON.stringify({ session: credentials }),
    });

    // console.log('🔑 Raw login response:', response);
    // console.log('🔑 Extracted token:', response.data.access_token);
    
    this.token = response.data.access_token;
    return this.token;
  }

  async logout(): Promise<void> {
    if (this.token) {
      await this.request('/api/tokens/logout', { method: 'DELETE' });
      this.token = undefined;
    }
    this.disconnect();
  }

  // Player Management
  async createPlayer(data: CreatePlayerRequest): Promise<Player> {
    const response = await this.request<{ data: Player }>('/api/players', {
      method: 'POST',
      body: JSON.stringify({ player: data }),
    });
    return response.data;
  }

  async getCurrentPlayer(): Promise<Player> {
    const response = await this.request<{ data: Player }>('/api/players/me');
    return response.data;
  }

  // Game Management
  async getGames(): Promise<Game[]> {
    const response = await this.request<{ data: Game[] }>('/api/games');
    return response.data;
  }

  async getGame(id: number): Promise<Game> {
    const response = await this.request<{ data: Game }>(`/api/games/${id}`);
    return response.data;
  }

  async getGameByName(name: string): Promise<Game> {
    const games = await this.getGames();
    const game = games.find(g => g.name === name);
    if (!game) {
      throw new GameServerError(`Game not found: ${name}`);
    }
    return game;
  }

  // Game Session Management
  async createGameSession(gameId: number, data: CreateGameSessionRequest = {}): Promise<GameSession> {
    const response = await this.request<{ data: GameSession }>(`/api/games/${gameId}/sessions`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
    return response.data;
  }

  async getGameSessions(gameId: number): Promise<GameSession[]> {
    const response = await this.request<{ data: GameSession[] }>(`/api/games/${gameId}/sessions`);
    return response.data;
  }

  async getGameSession(gameId: number, sessionId: number): Promise<GameSession> {
    const response = await this.request<{ data: GameSession }>(`/api/games/${gameId}/sessions/${sessionId}`);
    return response.data;
  }

  async joinGameSession(gameId: number, sessionId: number, data: JoinGameSessionRequest = {}): Promise<GameSession> {
    const response = await this.request<{ data: GameSession }>(`/api/games/${gameId}/sessions/${sessionId}/join`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
    return response.data;
  }

  async leaveGameSession(gameId: number, sessionId: number): Promise<GameSession> {
    const response = await this.request<{ data: GameSession }>(`/api/games/${gameId}/sessions/${sessionId}/leave`, {
      method: 'POST',
    });
    return response.data;
  }

  async startGameSession(gameId: number, sessionId: number): Promise<GameSession> {
    const response = await this.request<{ data: GameSession }>(`/api/games/${gameId}/sessions/${sessionId}/start`, {
      method: 'POST',
    });
    return response.data;
  }

  async updateGameSession(
    gameId: number,
    sessionId: number,
    data: UpdateGameSessionRequest
  ): Promise<GameSession> {
    const response = await this.request<{ data: GameSession }>(`/api/games/${gameId}/sessions/${sessionId}`, {
      method: 'PUT',
      body: JSON.stringify({ game_session: data }),
    });
    return response.data;
  }

  // WebSocket Management
  subscribe(sessionId: number, callback: (session: GameSession) => void): void {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
      this.connect();
    }

    this.subscriptions.add(sessionId);

    this.on(`session:${sessionId}`, callback);

    // Send subscription message once connected
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.sendSubscription(sessionId);
    }
  }

  unsubscribe(sessionId: number): void {
    this.subscriptions.delete(sessionId);
    this.removeAllListeners(`session:${sessionId}`);
  }

  private connect(): void {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      return;
    }

    this.ws = new WebSocket(this.wsUrl);

    this.ws.on('open', () => {
      this.emit('connected');
      // Subscribe to all active subscriptions
      for (const sessionId of this.subscriptions) {
        this.sendSubscription(sessionId);
      }
    });

    this.ws.on('message', (data: WebSocket.Data) => {
      try {
        const message = JSON.parse(data.toString()) as GameSessionUpdateMessage;
        if (message.event === 'updated') {
          const sessionId = message.data.id;
          this.emit(`session:${sessionId}`, message.data);
        }
      } catch (error) {
        this.emit('error', new GameServerError('Failed to parse WebSocket message', 0, error));
      }
    });

    this.ws.on('close', () => {
      this.emit('disconnected');
      // Attempt to reconnect after a delay
      setTimeout(() => this.connect(), 3000);
    });

    this.ws.on('error', (error: Error) => {
      this.emit('error', new GameServerError('WebSocket error', 0, error));
    });
  }

  private sendSubscription(sessionId: number): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify({
        command: 'subscribe',
        identifier: JSON.stringify({
          channel: 'GameSessionChannel',
          id: sessionId
        })
      }));
    }
  }

  disconnect(): void {
    if (this.ws) {
      // Remove all event listeners before closing to prevent race conditions
      if (typeof this.ws.removeAllListeners === 'function') {
        this.ws.removeAllListeners();
      }

      // Only close if WebSocket is in a valid state for closing
      if (this.ws.readyState === WebSocket.OPEN || this.ws.readyState === WebSocket.CONNECTING) {
        try {
          this.ws.close();
        } catch (error) {
          // Ignore errors during close, we're disconnecting anyway
        }
      }

      this.ws = undefined;
    }
    this.subscriptions.clear();
    this.removeAllListeners();
  }

  // User Management
  async createUser(data: CreateUserRequest): Promise<User> {
    const response = await this.request<{ data: User }>('/api/users', {
      method: 'POST',
      body: JSON.stringify({ user: data }),
    });
    return response.data;
  }

  async updateUser(userId: number, data: UpdateUserRequest): Promise<User> {
    const response = await this.request<{ data: User }>(`/api/users/${userId}`, {
      method: 'PUT',
      body: JSON.stringify({ user: data }),
    });
    return response.data;
  }

  async deleteUser(userId: number): Promise<void> {
    await this.request(`/api/users/${userId}`, {
      method: 'DELETE',
    });
  }

  async getCurrentUser(): Promise<User> {
    const response = await this.request<{ data: User }>('/api/users/me');
    return response.data;
  }

  // Admin Game Management
  async createGame(data: CreateGameRequest): Promise<Game> {
    const response = await this.request<{ data: Game }>('/api/admin/games', {
      method: 'POST',
      body: JSON.stringify(data), // No wrapper - matches Ruby client
    });
    return response.data;
  }

  async updateGame(gameId: number, data: CreateGameRequest): Promise<Game> {
    const response = await this.request<{ data: Game }>(`/api/admin/games/${gameId}`, {
      method: 'PUT',
      body: JSON.stringify(data), // No wrapper - matches Ruby client
    });
    return response.data;
  }

  async deleteGame(gameId: number): Promise<void> {
    await this.request(`/api/admin/games/${gameId}`, {
      method: 'DELETE',
    });
  }

  // Admin User Management
  async createAdminUser(data: CreateUserRequest): Promise<User> {
    const response = await this.request<{ data: User }>('/api/admin/users', {
      method: 'POST',
      body: JSON.stringify({ user: data }),
    });
    return response.data;
  }

  async makeUserAdmin(userId: number): Promise<User> {
    const response = await this.request<{ data: User }>(`/api/admin/users/${userId}/make_admin`, {
      method: 'POST',
    });
    return response.data;
  }

  async removeUserAdmin(userId: number): Promise<User> {
    const response = await this.request<{ data: User }>(`/api/admin/users/${userId}/remove_admin`, {
      method: 'POST',
    });
    return response.data;
  }

  async listAllUsers(): Promise<User[]> {
    const response = await this.request<{ data: User[] }>('/api/admin/users');
    return response.data;
  }

  // HTTP Request Helper
  private async request<T>(path: string, options: RequestInit = {}): Promise<T> {
    const url = `${this.apiUrl}${path}`;

    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...((options.headers as Record<string, string>) || {}),
    };

    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
      // console.log('🔑 Adding Authorization header:', headers['Authorization']);
    } else {
      // console.log('🔑 No token available for request');
    }

    const response = await fetch(url, {
      ...options,
      headers,
    });

    if (!response.ok) {
      let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
      try {
        const errorData = await response.json();
        errorMessage = errorData.error || errorData.message || errorMessage;
      } catch {
        // Use default error message if JSON parsing fails
      }
      throw new GameServerError(errorMessage, response.status);
    }

    return response.json() as Promise<T>;
  }
}
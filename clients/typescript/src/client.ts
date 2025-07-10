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
  }

  // Authentication
  async login(credentials: LoginRequest): Promise<string> {
    const response = await this.request<{ token: string }>('/api/tokens/login', {
      method: 'POST',
      body: JSON.stringify({ user: credentials }),
    });

    this.token = response.token;
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
    return this.request<Player>('/api/players', {
      method: 'POST',
      body: JSON.stringify({ player: data }),
    });
  }

  async getCurrentPlayer(): Promise<Player> {
    return this.request<Player>('/api/players/me');
  }

  // Game Management
  async getGames(): Promise<Game[]> {
    return this.request<Game[]>('/api/games');
  }

  async getGame(id: number): Promise<Game> {
    return this.request<Game>(`/api/games/${id}`);
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
    return this.request<GameSession>(`/api/games/${gameId}/sessions`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async getGameSessions(gameId: number): Promise<GameSession[]> {
    return this.request<GameSession[]>(`/api/games/${gameId}/sessions`);
  }

  async getGameSession(gameId: number, sessionId: number): Promise<GameSession> {
    return this.request<GameSession>(`/api/games/${gameId}/sessions/${sessionId}`);
  }

  async joinGameSession(gameId: number, sessionId: number, data: JoinGameSessionRequest = {}): Promise<GameSession> {
    return this.request<GameSession>(`/api/games/${gameId}/sessions/${sessionId}/join`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async leaveGameSession(gameId: number, sessionId: number): Promise<GameSession> {
    return this.request<GameSession>(`/api/games/${gameId}/sessions/${sessionId}/leave`, {
      method: 'POST',
    });
  }

  async startGameSession(gameId: number, sessionId: number): Promise<GameSession> {
    return this.request<GameSession>(`/api/games/${gameId}/sessions/${sessionId}/start`, {
      method: 'POST',
    });
  }

  async updateGameSession(
    gameId: number, 
    sessionId: number, 
    data: UpdateGameSessionRequest
  ): Promise<GameSession> {
    return this.request<GameSession>(`/api/games/${gameId}/sessions/${sessionId}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
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
      this.ws.close();
      this.ws = undefined;
    }
    this.subscriptions.clear();
    this.removeAllListeners();
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
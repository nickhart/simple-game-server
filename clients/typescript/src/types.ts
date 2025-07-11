// API Response Types
export interface ApiResponse<T = any> {
  data?: T;
  error?: string;
  message?: string;
}

// Core Models
export interface User {
  id: number;
  email: string;
  name: string;
  admin: boolean;
  created_at: string;
  updated_at: string;
}

export interface Player {
  id: string; // UUID
  user_id: number;
  name: string;
  created_at: string;
  updated_at: string;
}

export interface Game {
  id: number;
  name: string;
  description: string;
  min_players: number;
  max_players: number;
  state_schema: Record<string, any>;
  created_at: string;
  updated_at: string;
}

export interface GameSession {
  id: number;
  game_id: number;
  status: 'waiting' | 'active' | 'finished';
  state: Record<string, any>;
  current_player_index: number | null;
  winner_index: number | null;
  creator_id: string; // UUID
  created_at: string;
  updated_at: string;
  players: Player[];
  game: Game;
  current_player?: Player;
}

// API Request Types
export interface LoginRequest {
  email: string;
  password: string;
}

export interface CreatePlayerRequest {
  name: string;
}

export interface CreateGameSessionRequest {
  // Optional properties for game session creation
}

export interface JoinGameSessionRequest {
  // Optional properties for joining
}

export interface UpdateGameSessionRequest {
  state?: Record<string, any>;
  status?: 'waiting' | 'active' | 'finished';
  current_player_index?: number;
  winner_index?: number;
}

export interface CreateUserRequest {
  email: string;
  password: string;
  password_confirmation?: string;
}

export interface UpdateUserRequest {
  email?: string;
  password?: string;
  password_confirmation?: string;
}

export interface CreateGameRequest {
  name: string;
  state_json_schema: string; // JSON string
  min_players?: number;
  max_players?: number;
}

// WebSocket Types
export interface WebSocketMessage {
  event: string;
  data: any;
}

export interface GameSessionUpdateMessage extends WebSocketMessage {
  event: 'updated';
  data: GameSession;
}

// Client Configuration
export interface ClientConfig {
  apiUrl: string;
  token?: string;
  wsUrl?: string;
}

// Error Types
export class GameServerError extends Error {
  constructor(
    message: string,
    public statusCode?: number,
    public response?: any
  ) {
    super(message);
    this.name = 'GameServerError';
  }
}
# Simple Game Server - WebSocket Refactor Plan (Protocol-Agnostic)

## Goal
Migrate from Rails' Action Cable (which uses a custom subprotocol) to a standard, protocol-agnostic WebSocket API using plain JSON messages.
This will enable support for:
- iOS (Swift)
- Android (Kotlin/Java)
- Flutter (Dart)
- Web (React, etc.)
- CLI clients (Ruby, Python, Go, etc.)

## Why
- Action Cable is Rails-specific and not supported on non-browser clients.
- Reduces complexity and improves cross-platform compatibility.
- Simplifies client implementations using standard WebSocket libraries.

---

## Phase 1: Set up plain WebSocket endpoint in Rails

### 1. Create a minimal WebSocket controller
Use `faye-websocket` or the `websocket-driver` gem (already a dependency of Action Cable).

- Create a `WebSocketController` (or `WsController`) using `ActionController::Metal` for performance.
- Mount it at `/ws/game_session`.

Example stub controller:
```ruby
class WsController < ActionController::Metal
  include ActionController::Live

  def game_session
    if Faye::WebSocket.websocket?(request.env)
      ws = Faye::WebSocket.new(request.env)

      ws.on :open do |event|
        Rails.logger.info "[WS] Connection opened"
      end

      ws.on :message do |event|
        Rails.logger.info "[WS] Received message: #{event.data}"
        ws.send({ event: "echo", data: event.data }.to_json)
      end

      ws.on :close do |event|
        Rails.logger.info "[WS] Connection closed"
        ws = nil
      end

      ws.rack_response
    else
      [426, { 'Content-Type' => 'text/plain' }, ['Upgrade required']]
    end
  end
end
```

### 2. Add route
```ruby
Rails.application.routes.draw do
  get "/ws/game_session", to: "ws#game_session"
end
```

### 3. Test with a standard WebSocket client
- Use `wscat` or any WebSocket tester.
- Confirm basic connection, message sending, and receiving works.

---

## Phase 2: Define clean JSON message schema

### 1. Create a spec for messages
Example:
```json
{
  "action": "subscribe",
  "game_session_id": "123"
}
```

Server response:
```json
{
  "event": "game_session_update",
  "game_session_id": "123",
  "state": { ... }
}
```

### 2. Document message types:
- `subscribe`
- `unsubscribe`
- `player_move`
- `game_session_update`
- `error`

---

## Phase 3: Implement server-side logic

- When a client subscribes to a game session:
  - Store the connection.
  - Push updates when the game session changes (reuse existing event triggers).
- Handle disconnects and cleanup.

---

## Phase 4: Update clients

### 1. Update CLI client
- Use `faye-websocket` gem.
- Remove `action_cable_client`.
- Connect directly to `/ws/game_session`.
- Send/receive plain JSON.

### 2. Create stubs for:
- iOS using `URLSessionWebSocketTask`.
- Android using `okhttp-ws`.
- Flutter using `web_socket_channel`.

---

## Phase 5: Gradual deprecation of Action Cable

- Keep Action Cable running during transition.
- Migrate CLI and test apps first.
- Later, migrate web clients if needed.
- Finally, remove Action Cable if fully replaced.

---

## Phase 6: Harden and optimize

- Add authentication (JWT over query param or initial message).
- Implement connection limits, idle timeouts.
- Monitor connections using Rails logs and metrics.

---

## Bonus: Next steps
- Abstract WebSocket handler behind a service class (`GameSessionWebSocketHandler`).
- Optionally use `anycable` or external WebSocket server in future for scaling.

---

## Summary

| Phase  | Task                                     | Status |
|--------|------------------------------------------|--------|
| Phase 1 | Create plain WebSocket endpoint          |        |
| Phase 2 | Define JSON message schema               |        |
| Phase 3 | Implement server-side message handling   |        |
| Phase 4 | Update CLI client to use plain WebSocket |        |
| Phase 5 | Migrate & deprecate Action Cable         |        |
| Phase 6 | Harden, optimize, and scale              |        |

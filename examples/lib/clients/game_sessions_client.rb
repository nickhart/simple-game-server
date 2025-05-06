class GameSessionsClient
  def initialize(api_client)
    @http = api_client
  end

  def list(game_id)
    @http.get("/api/games/#{game_id}/sessions")
  end

  def get(game_id, session_id)
    @http.get("/api/games/#{game_id}/sessions/#{session_id}")
  end

  def create(game_id)
    @http.post("/api/games/#{game_id}/sessions")
  end

  def join(game_id, session_id)
    @http.post("/api/games/#{game_id}/sessions/#{session_id}/join")
  end

  def start(game_id, session_id)
    @http.post("/api/games/#{game_id}/sessions/#{session_id}/start")
  end

  def update(game_id, session_id, state:, status: "active")
    @http.put("/api/games/#{game_id}/sessions/#{session_id}", {
      game_session: {
        state: state,
        status: status
      }
    })
  end

  def leave(game_id, session_id)
    @http.delete("/api/games/#{game_id}/sessions/#{session_id}/leave")
  end
end

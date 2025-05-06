

class AdminGamesClient
  def initialize(api_client)
    @http = api_client
  end

  def list
    @http.get("/api/admin/games")
  end

  def update(game_id, schema)
    @http.patch("/api/admin/games/#{game_id}", { state_json_schema: schema })
  end

  def create(name, schema)
    @http.post("/api/admin/games", { name: name, state_json_schema: schema })
  end
end
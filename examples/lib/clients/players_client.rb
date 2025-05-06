

class PlayersClient
  def initialize(api_client)
    @http = api_client
  end

  def me
    @http.get("/api/players/me")
  end

  def create(name)
    @http.post("/api/players", {
      player: {
        name: name
      }
    })
  end
end
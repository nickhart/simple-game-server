class GamesClient
  def initialize(api_client)
    @http = api_client
  end

  def list
    @http.get("/api/games")
  end

  def find_by_name(name)
    result = list
    return result unless result.success?

    game = result.data.find { |g| g["name"] == name }
    return Result.failure("Game '#{name}' not found") unless game

    Result.success(game)
  end
end

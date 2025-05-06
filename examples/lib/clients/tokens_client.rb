class TokensClient
  def initialize(api_client)
    @http = api_client
  end

  def login(email, password)
    body = {
      session: {
        email: email,
        password: password
      }
    }
    response = @http.post("/api/tokens/login", body)
    return response unless response.success?

    Result.success(response.data["access_token"])
  end
end
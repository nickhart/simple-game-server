

class UsersClient
  def initialize(api_client)
    @http = api_client
  end

  def list
    @http.get("/api/users")
  end

  def get(id)
    @http.get("/api/users/#{id}")
  end

  def create(email, password)
    @http.post("/api/users", {
      user: {
        email: email,
        password: password
      }
    })
  end

  def update(id, attributes)
    @http.patch("/api/users/#{id}", {
      user: attributes
    })
  end

  def delete(id)
    @http.delete("/api/users/#{id}")
  end
end
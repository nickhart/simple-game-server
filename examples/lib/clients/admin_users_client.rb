


class AdminUsersClient
  def initialize(api_client)
    @http = api_client
  end

  def list
    @http.get("/api/admin/users")
  end

  def create(email, password)
    @http.post("/api/admin/users", {
      user: {
        email: email,
        password: password
      }
    })
  end

  def make_admin(user_id)
    @http.post("/api/admin/users/#{user_id}/make_admin")
  end
end
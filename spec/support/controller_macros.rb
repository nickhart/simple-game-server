module ControllerMacros
  def sign_in(user)
    # Create access and refresh tokens
    access_token = Token.create_access_token(user)
    refresh_token = Token.create_refresh_token(user)

    # Set the Authorization header with the JWT string
    request.headers['Authorization'] = "Bearer #{user.to_jwt(access_token)}"
  end

  def authorize_as(user)
    token = Token.create_access_token(user)
    request.headers["Authorization"] = "Bearer #{user.to_jwt(token)}"
  end  
end

RSpec.configure do |config|
  config.include ControllerMacros, type: :controller
end

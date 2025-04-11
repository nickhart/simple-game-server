module ControllerMacros
  def sign_in(user)
    # Create access and refresh tokens
    access_token = Token.create_access_token(user)
    refresh_token = Token.create_refresh_token(user)

    # Set the Authorization header
    request.headers['Authorization'] = "Bearer #{access_token.token}"
  end

  def sign_out
    request.headers['Authorization'] = nil
  end
end

RSpec.configure do |config|
  config.include ControllerMacros, type: :controller
end 
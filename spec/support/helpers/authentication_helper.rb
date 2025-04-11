module AuthenticationHelper
  def sign_in(user)
    token = generate_token(user)
    request.headers["Authorization"] = "Token token=\"#{token}\""
  end

  private

  def generate_token(user)
    payload = {
      user_id: user.id,
      token_version: user.token_version,
      role: user.role
    }
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :controller
  config.include AuthenticationHelper, type: :request
end

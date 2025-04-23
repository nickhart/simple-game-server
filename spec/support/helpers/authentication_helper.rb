# module AuthenticationHelper
#   def sign_in(user)
#     token = generate_token(user)
#     request.headers["Authorization"] = "Bearer #{token}"
#   end

#   private

#   def generate_token(user)
#     payload = {
#       user_id: user.id,
#       token_version: user.token_version,
#       role: user.role
#     }
#     JwtService.encode(payload)
#   end
# end

# RSpec.configure do |config|
#   config.include AuthenticationHelper, type: :controller
#   config.include AuthenticationHelper, type: :request
# end

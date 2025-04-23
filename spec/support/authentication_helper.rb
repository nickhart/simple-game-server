
# def generate_token_for(user)
#   access_token = Token.create_access_token(user)
#   payload = {
#     user_id: user.id,
#     jti: access_token.jti,
#     token_version: user.token_version,
#     role: user.role
#   }
#   JWT.encode(payload, Rails.application.credentials.secret_key_base)
# end

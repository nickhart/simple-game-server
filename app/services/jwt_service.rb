class JwtService
    SECRET = Rails.application.credentials.secret_key_base
  
    def self.encode(user)
      payload = {
        user_id: user.id,
        role: user.role,
        token_version: user.token_version,
        exp: 1.hour.from_now.to_i
      }
      JWT.encode(payload, SECRET)
    end
  
    def self.decode(token)
      decoded = JWT.decode(token, SECRET).first
      HashWithIndifferentAccess.new(decoded)
    rescue JWT::DecodeError
      nil
    end
  end
  
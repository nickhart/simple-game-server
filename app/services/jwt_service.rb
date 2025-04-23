class JwtService
  SECRET = Rails.application.credentials.secret_key_base.presence ||
           ENV["JWT_SECRET_KEY"] ||
           (Rails.env.test? ? "test_secret_key" : abort("❌ Missing secret_key_base"))

  def self.encode(payload)
    payload = normalize_payload(payload) if payload.is_a?(Hash)
    payload = build_payload_from_user(payload) if payload.is_a?(User)
    JWT.encode(payload, SECRET, "HS256")
  end

  def self.build_payload_from_user(user)
    {
      user_id: user.id,
      email: user.email,
      role: user.role,
      token_version: user.token_version
    }
  end

  def self.extract_value(payload, user, key)
    payload[key] || (user.respond_to?(key) ? user.public_send(key) : user[key.to_s])
  end

  def self.normalize_payload(payload)
    user = payload[:user] || payload[:data] || {}

    {
      user_id: extract_value(payload, user, :user_id),
      email: extract_value(payload, user, :email),
      role: extract_value(payload, user, :role),
      token_version: extract_value(payload, user, :token_version),
      jti: payload[:jti],
      exp: payload[:exp]
    }.compact
  end

  def self.decode(token)
    JWT.decode(token, SECRET, true, { algorithm: "HS256" }).first&.transform_keys(&:to_sym)
  rescue JWT::DecodeError
    nil
  end
end

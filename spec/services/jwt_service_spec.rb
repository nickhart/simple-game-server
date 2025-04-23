require "rails_helper"

RSpec.describe JwtService do
  let(:user) { create(:user) }

  describe ".encode" do
    it "returns a valid JWT with expected claims" do
      access_token = Token.create_access_token(user)
      user.reload  # Ensure we have all latest DB-persisted attributes
      puts "user: #{user.inspect}"
      payload = {
        user_id: user.id,
        role: user.role,
        token_version: user.token_version,
        jti: access_token.jti,
        exp: access_token.expires_at.to_i,
        email: user.email
      }
      token = JwtService.encode(payload)
      decoded = described_class.decode(token)

      puts "decoded JWT claims: #{decoded.inspect}"
      expect(decoded[:user_id]).to eq(user.id)
      expect(decoded[:role]).to eq(user.role)
      expect(decoded[:token_version]).to eq(user.token_version)
      expect(decoded[:exp]).to eq(access_token.expires_at.to_i)
    end
  end

  describe ".decode" do
    it "returns nil for invalid token" do
      expect(described_class.decode("bogus.token.here")).to be_nil
    end
  end
end

require "rails_helper"

RSpec.describe JwtService do
  let(:user) { create(:user) }

  describe ".encode" do
    it "returns a valid JWT with expected claims" do
      token = described_class.encode(user)
      decoded = described_class.decode(token)

      expect(decoded["user_id"]).to eq(user.id)
      expect(decoded["role"]).to eq(user.role)
      expect(decoded["token_version"]).to eq(user.token_version)
      expect(decoded["exp"]).to be_within(5).of(1.hour.from_now.to_i)
    end
  end

  describe ".decode" do
    it "returns nil for invalid token" do
      expect(described_class.decode("bogus.token.here")).to be_nil
    end
  end
end

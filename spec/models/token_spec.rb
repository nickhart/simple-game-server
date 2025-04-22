require "rails_helper"

RSpec.describe Token, type: :model do
  let(:user) { create(:user) }

  describe "validations" do
    it "requires a jti" do
      token = build(:token, jti: nil)
      expect(token).not_to be_valid
      expect(token.errors[:jti]).to include("can't be blank")
    end

    it "requires a unique jti" do
      existing_token = create(:token)
      token = build(:token, jti: existing_token.jti)
      expect(token).not_to be_valid
      expect(token.errors[:jti]).to include("has already been taken")
    end

    it "requires a token_type" do
      token = build(:token, token_type: nil)
      expect(token).not_to be_valid
      expect(token.errors[:token_type]).to include("can't be blank")
    end

    it "requires token_type to be access or refresh" do
      token = build(:token, token_type: "invalid")
      expect(token).not_to be_valid
      expect(token.errors[:token_type]).to include("is not included in the list")
    end

    it "requires an expires_at" do
      token = build(:token, expires_at: nil)
      expect(token).not_to be_valid
      expect(token.errors[:expires_at]).to include("can't be blank")
    end
  end

  describe ".create_access_token" do
    it "creates an access token" do
      token = described_class.create_access_token(user)
      expect(token).to be_valid
      expect(token.token_type).to eq("access")
      expect(token.expires_at).to be > 14.minutes.from_now
      expect(token.expires_at).to be < 16.minutes.from_now
    end
  end

  describe ".create_refresh_token" do
    it "creates a refresh token" do
      token = described_class.create_refresh_token(user)
      expect(token).to be_valid
      expect(token.token_type).to eq("refresh")
      expect(token.expires_at).to be > 6.days.from_now
      expect(token.expires_at).to be < 8.days.from_now
    end
  end

  describe "#expired?" do
    it "returns true for expired tokens" do
      token = build(:token, :expired)
      expect(token.expired?).to be true
    end

    it "returns false for active tokens" do
      token = build(:token)
      expect(token.expired?).to be false
    end
  end

  describe "#status_active?" do
    it "returns true for active tokens" do
      token = build(:token)
      expect(token.status_active?).to be true
    end

    it "returns false for expired tokens" do
      token = build(:token, :expired)
      expect(token.status_active?).to be false
    end
  end

  describe "factory traits" do
    it "creates a token with an invalid jti using :invalid_jti" do
      token = build(:token, :invalid_jti)
      expect(token.jti).to eq("totally-wrong-jti")
    end

    it "creates a token expiring soon with :soon_expiring trait" do
      token = build(:token, :soon_expiring)
      expect(token.expires_at).to be <= 15.seconds.from_now
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let!(:active_access_token) { create(:token, user: user) }
    let!(:expired_access_token) { create(:token, :expired, user: user) }
    let!(:active_refresh_token) { create(:token, :refresh, user: user) }
    let!(:expired_refresh_token) { create(:token, :refresh, :expired, user: user) }

    describe ".active" do
      it "returns only active tokens" do
        expect(described_class.active).to include(active_access_token, active_refresh_token)
        expect(described_class.active).not_to include(expired_access_token, expired_refresh_token)
      end
    end

    describe ".refresh_tokens" do
      it "returns only refresh tokens" do
        expect(described_class.refresh_tokens).to include(active_refresh_token, expired_refresh_token)
        expect(described_class.refresh_tokens).not_to include(active_access_token, expired_access_token)
      end
    end

    describe ".access_tokens" do
      it "returns only access tokens" do
        expect(described_class.access_tokens).to include(active_access_token, expired_access_token)
        expect(described_class.access_tokens).not_to include(active_refresh_token, expired_refresh_token)
      end
    end
  end
end

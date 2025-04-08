class Token < ApplicationRecord
  belongs_to :user

  validates :jti, presence: true, uniqueness: true
  validates :token_type, presence: true, inclusion: { in: %w[access refresh] }
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :refresh_tokens, -> { where(token_type: "refresh") }
  scope :access_tokens, -> { where(token_type: "access") }

  def self.generate_jti
    SecureRandom.uuid
  end

  def self.create_access_token(user)
    create!(
      user: user,
      jti: generate_jti,
      token_type: "access",
      expires_at: 15.minutes.from_now
    )
  end

  def self.create_refresh_token(user)
    create!(
      user: user,
      jti: generate_jti,
      token_type: "refresh",
      expires_at: 7.days.from_now
    )
  end

  def expired?
    expires_at < Time.current
  end

  def active?
    !expired?
  end
end

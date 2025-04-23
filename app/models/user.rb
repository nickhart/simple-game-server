class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :player, dependent: :destroy
  has_many :tokens, dependent: :destroy

  # Role management
  ROLES = %w[player admin].freeze
  validates :role, presence: true, inclusion: { in: ROLES }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token_version, presence: true

  before_validation :set_initial_token_version, on: :create

  # Add token versioning for security
  attribute :token_version, :integer, default: 1

  def invalidate_token!
    # for now disable this warning about running validations because our simple
    # token_version doesn't have any validations. it's just for invalidating prior tokens.
    # rubocop:disable Rails/SkipsModelValidations
    increment!(:token_version)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def admin?
    role == "admin"
  end

  def player?
    role == "player"
  end

  def make_admin!
    update!(role: "admin")
  end

  def remove_admin!
    update!(role: "player")
  end

  def to_jwt(token)
    payload = {
      user_id: id,
      role: role,
      token_version: token_version,
      jti: token.jti,
      exp: token.expires_at.to_i
    }

    JWT.encode(payload, Rails.application.credentials.secret_key_base, "HS256")
  end

  def create_player!
    return if player.present?
    return unless persisted? # don't try to create player if user hasn't been saved

    # Player creation is now explicit—this is not automatically called on user creation
    Rails.logger.debug { "[create_player!] about to build player for user_id=#{id}" }
    build_player(name: email.split("@").first)
    Rails.logger.debug { "[create_player!] built player: #{player.inspect}" }

    player.save!
  end

  private

  def set_initial_token_version
    self.token_version = 1 if token_version.nil?
  end
end

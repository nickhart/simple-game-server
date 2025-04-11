class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :players, dependent: :destroy
  has_many :tokens

  # Role management
  ROLES = %w[player admin].freeze
  validates :role, presence: true, inclusion: { in: ROLES }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: :password_digest_changed?
  validates :token_version, presence: true

  before_validation :set_initial_token_version, on: :create

  # Add token versioning for security
  attribute :token_version, :integer, default: 0

  def invalidate_token!
    increment!(:token_version)
  end

  def admin?
    role == "admin"
  end

  def player?
    role == "player"
  end

  private

  def set_initial_token_version
    self.token_version = 1 if token_version.nil?
  end
end

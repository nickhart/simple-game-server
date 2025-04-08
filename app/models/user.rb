class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :players, dependent: :destroy

  # Add token versioning for security
  attribute :token_version, :integer, default: 0

  def invalidate_token!
    update!(token_version: token_version + 1)
  end
end

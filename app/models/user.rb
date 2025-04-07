class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :players, dependent: :destroy

  validates :role, presence: true, inclusion: { in: %w[admin player] }

  def admin?
    role == "admin"
  end

  def player?
    role == "player"
  end
end

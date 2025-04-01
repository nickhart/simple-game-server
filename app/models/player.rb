class Player < ApplicationRecord
  belongs_to :game_session
  belongs_to :user

  validates :name, presence: true
  validates :user, presence: true
  validates :game_session, presence: true
end

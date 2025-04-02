class Player < ApplicationRecord
  belongs_to :game_session
  belongs_to :user

  validates :name, presence: true
end

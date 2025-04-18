class Player < ApplicationRecord
  # Use UUID as primary key
  self.primary_key = "id"

  belongs_to :user, optional: true
  belongs_to :game_session, optional: true

  validates :name, presence: true

  before_create :ensure_uuid

  private

  def ensure_uuid
    self.id = SecureRandom.uuid if id.nil?
  end
end

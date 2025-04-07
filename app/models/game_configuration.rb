class GameConfiguration < ApplicationRecord
  belongs_to :game

  validates :state_schema, presence: true
  validate :validate_state_schema

  private

  def validate_state_schema
    return if state_schema.blank?

    unless state_schema.is_a?(Hash)
      errors.add(:state_schema, "must be a hash")
      return
    end

    state_schema.each do |key, value|
      case value
      when Array
        # Array type - e.g., board: []
        next
      when Hash
        # Hash type - e.g., scores: {}
        next
      when Symbol
        # Simple attribute - e.g., current_player: :symbol
        next
      else
        errors.add(:state_schema, "invalid type for key #{key}: #{value.class}")
      end
    end
  end
end

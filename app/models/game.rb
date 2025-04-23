class Game < ApplicationRecord
  has_many :game_sessions, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :state_json_schema, presence: true
  validates :min_players, presence: true, numericality: { greater_than_or_equal_to: 2 }
  validates :max_players, presence: true, numericality: { less_than_or_equal_to: 10 }
  validate :max_players_greater_than_min_players
  validate :validate_state_json_schema_format

  def max_players_greater_than_min_players
    return unless min_players && max_players

    errors.add(:max_players, :must_be_greater_than_min_players) if max_players < min_players
  end

  def validate_state_json_schema_format
    return if state_json_schema.blank?

    begin
      parsed = JSON.parse(state_json_schema)
      JSONSchemer.schema(parsed)
    rescue JSON::ParserError => e
      errors.add(:state_json_schema, :invalid_json, message: e.message)
    rescue StandardError => e
      errors.add(:state_json_schema, :unparsable_schema, message: e.message)
    end
  end
end

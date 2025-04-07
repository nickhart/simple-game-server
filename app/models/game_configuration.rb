class GameConfiguration < ApplicationRecord
  belongs_to :game

  validates :state_schema, presence: true
  validate :validate_schema_type

  def validate_schema_type
    return unless state_schema.is_a?(Hash)

    case state_schema[:type]
    when "object"
      validate_object_schema
    when "array"
      validate_array_schema
    else
      errors.add(:state_schema, "must be an object or array schema")
    end
  end

  private

  def validate_object_schema
    unless state_schema[:properties].is_a?(Hash)
      errors.add(:state_schema, "object schema must have properties")
      return
    end

    state_schema[:properties].each do |key, value|
      validate_property(key, value)
    end
  end

  def validate_array_schema
    unless state_schema[:items].is_a?(Hash)
      errors.add(:state_schema, "array schema must have items")
      return
    end

    validate_property("items", state_schema[:items])
  end

  def validate_property(key, value)
    case value[:type]
    when "string"
      validate_string_property(key, value)
    when "array"
      validate_array_property(key, value)
    when "object"
      validate_object_property(key, value)
    else
      errors.add(:state_schema, "invalid type for property #{key}")
    end
  end

  def validate_string_property(key, value)
    return unless value[:enum]

    errors.add(:state_schema, "enum must be an array for property #{key}") unless value[:enum].is_a?(Array)
  end

  def validate_array_property(key, value)
    errors.add(:state_schema, "array items must be defined for property #{key}") unless value[:items].is_a?(Hash)
  end

  def validate_object_property(key, value)
    return if value[:properties].is_a?(Hash)

    error_message = "object properties must be defined for property #{key}"
    errors.add(:state_schema, error_message)
  end
end

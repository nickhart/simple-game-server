require_relative "test"

Rails.application.configure do
  config.active_record.migration_error = false
  config.active_record.maintain_test_schema = false
  config.active_record.dump_schema_after_migration = false
end

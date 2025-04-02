require_relative "test"

Rails.application.configure do
  # Disable ActiveRecord completely
  config.active_record.migration_error = false
  config.active_record.maintain_test_schema = false
  config.active_record.dump_schema_after_migration = false

  # Prevent database connection attempts
  config.active_record.establish_connection = ->(*) {}

  # Additional performance optimizations for unit tests
  config.cache_classes = true
  config.eager_load = false
  config.action_controller.perform_caching = false
  config.action_mailer.perform_caching = false
  config.active_support.deprecation = :stderr
end

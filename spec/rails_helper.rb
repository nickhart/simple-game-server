require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "factory_bot_rails"
require "database_cleaner/active_record"

# Load all support files (helpers, matchers, etc.)
Rails.root.glob("spec/support/**/*.rb").each { |f| require f }

# Ensure the database schema is up to date
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Use ActiveRecord fixtures
  config.fixture_paths = [Rails.root.join("spec/fixtures").to_s]

  # Use database transactions for tests (recommended for most cases)
  config.use_transactional_fixtures = false

  # Setup DatabaseCleaner for consistent DB state
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation, { reset_ids: true }
    DatabaseCleaner.clean_with(:truncation)

    # Reset all primary key sequences
    ActiveRecord::Base.connection.tables.each do |t|
      ActiveRecord::Base.connection.reset_pk_sequence!(t)
    end
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # Automatically infer spec type from file location
  config.infer_spec_type_from_file_location!

  # Filter Rails gems from backtraces
  config.filter_rails_from_backtrace!

  # Include FactoryBot methods (e.g. create, build)
  config.include FactoryBot::Syntax::Methods
end

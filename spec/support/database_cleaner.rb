require "database_cleaner/active_record"

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner[:active_record].clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner[:active_record].strategy = :transaction
  end

  config.before(:each, truncation: true) do
    DatabaseCleaner[:active_record].strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner[:active_record].start
  end

  config.append_after(:each) do
    DatabaseCleaner[:active_record].clean

    # Reset primary key sequences *after* each truncation-based test
    if DatabaseCleaner[:active_record].strategy == :truncation
      %w[users players tokens games game_sessions game_players].each do |table|
        ActiveRecord::Base.connection.reset_pk_sequence!(table)
      end
    end
  end
end

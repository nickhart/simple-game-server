require "database_cleaner/active_record"

RSpec.configure do |config|
  config.before(:each, truncation: true) do
    DatabaseCleaner[:active_record].strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner[:active_record].strategy = :transaction
  end

  config.before(:each) do
    DatabaseCleaner[:active_record].start
  end

  config.append_after(:each) do
    DatabaseCleaner[:active_record].clean

    # Reset primary key sequences *after* each truncation-based test
    puts "DatabaseCleaner strategy: #{DatabaseCleaner[:active_record].strategy.class.name}"
    if DatabaseCleaner[:active_record].strategy.is_a?(DatabaseCleaner::ActiveRecord::Truncation)
      %w[users players tokens games game_sessions game_players].each do |table|
        puts "reseting primary key sequence for #{table}"
        ActiveRecord::Base.connection.reset_pk_sequence!(table)
      end
    end
  end
end

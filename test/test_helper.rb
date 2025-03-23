ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    if ENV["SKIP_DB_TESTS"].nil?
      fixtures :all
    else
      def setup
        skip "Skipping database tests in CI" if self.class.name.start_with?("Test::") && method_name.start_with?("test_")
      end
    end

    # Add more helper methods to be used by all tests here...
  end
end

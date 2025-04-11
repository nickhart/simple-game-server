require "simplecov"
require "simplecov-cobertura"
require "bcrypt"

SimpleCov.start "rails" do
  enable_coverage :branch

  add_filter "/bin/"
  add_filter "/db/"
  add_filter "/test/"

  add_group "Controllers", "app/controllers"
  add_group "Models", "app/models"
  add_group "Services", "app/services"

  SimpleCov.minimum_coverage 90
  SimpleCov.minimum_coverage_by_file 80

  if ENV["CI"]
    formatter SimpleCov::Formatter::CoberturaFormatter
  else
    formatter SimpleCov::Formatter::HTMLFormatter
  end
end

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
        if self.class.name.start_with?("Test::") && method_name.start_with?("test_")
          skip "Skipping database tests in CI"
        end
      end
    end

    # Add more helper methods to be used by all tests here...
    def generate_jwt_token(user)
      payload = {
        user_id: user.id,
        token_version: user.token_version,
        role: user.role
      }
      JWT.encode(payload, Rails.application.credentials.secret_key_base)
    end

    def auth_headers(user)
      token = generate_jwt_token(user)
      { "Authorization" => "Bearer #{token}" }
    end
  end
end

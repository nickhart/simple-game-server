ENV["RAILS_ENV"] = "test_unit"
ENV["DISABLE_DATABASE"] = "true"

require "minitest/autorun"
require "active_support"
require "active_support/test_case"
require "active_support/testing/autorun"

# Prevent database connection attempts
module ActiveRecord
  class Base
    def self.establish_connection(*args)
      # No-op to prevent database connections
    end
  end
end

class UnitTest < Minitest::Test
  # Add any shared test helper methods here
end

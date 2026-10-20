ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel processes, each with its own test database. Threads shared one
    # database connection and failed with Postgres errors once the suite passed 50 tests.
    # Processes need fork, which Windows doesn't have, so Windows runs in a single process.
    parallelize(workers: Gem.win_platform? ? 1 : :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Email confirmation is off unless REQUIRE_EMAIL_CONFIRMATION=true (see User)
    def with_email_confirmation_required
      previous = ENV["REQUIRE_EMAIL_CONFIRMATION"]
      ENV["REQUIRE_EMAIL_CONFIRMATION"] = "true"
      yield
    ensure
      ENV["REQUIRE_EMAIL_CONFIRMATION"] = previous
    end
  end
end

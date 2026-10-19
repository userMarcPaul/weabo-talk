require "test_helper"

class Forms::ValidationRulesTest < ActiveSupport::TestCase
  # Password (must match the User model: Devise only requires 8 characters)
  test "password accepted by the User model should have no errors" do
    assert_empty Forms::ValidationRules.validate("password", "password123")
  end

  test "short password should be rejected" do
    assert_includes Forms::ValidationRules.validate("password", "short"), "Password must be at least 8 characters"
  end

  # Password Confirmation
  test "matching password confirmation should have no errors" do
    assert_empty Forms::ValidationRules.validate("password_confirmation", "password123", "password123")
  end

  test "different password confirmation should be rejected" do
    assert_includes Forms::ValidationRules.validate("password_confirmation", "password123", "other"), "Passwords must match"
  end
end

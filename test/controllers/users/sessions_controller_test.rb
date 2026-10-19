require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @unconfirmed = User.create!(email: "unconfirmed@example.com", password: "password123", password_confirmation: "password123")
  end

  # Unconfirmed accounts
  test "unconfirmed user with the right password should be sent to resend confirmation" do
    post user_session_path, params: { user: { email: "unconfirmed@example.com", password: "password123" } }

    assert_redirected_to new_user_confirmation_path(email: "unconfirmed@example.com")
  end

  test "email case should not matter for the unconfirmed check" do
    post user_session_path, params: { user: { email: "UNCONFIRMED@example.com", password: "password123" } }

    assert_redirected_to new_user_confirmation_path(email: "unconfirmed@example.com")
  end

  test "wrong password should not reveal that an unconfirmed account exists" do
    post user_session_path, params: { user: { email: "unconfirmed@example.com", password: "wrong-password" } }

    assert_response :unprocessable_entity
    assert_includes response.body, "Invalid email or password"
  end
end

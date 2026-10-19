require "test_helper"

class Users::UserMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:one)
  end

  # Password Reset
  test "reset_password_instructions should build email with reset link" do
    email = Users::UserMailer.reset_password_instructions(@user, "reset-token-123")

    assert_equal [ @user.email ], email.to
    assert_equal "Reset your WeaboTalk password", email.subject
    assert_includes html_body(email), "/users/password/edit?reset_password_token=reset-token-123"
  end

  # Email Confirmation
  test "confirmation_instructions should build email with confirmation link" do
    email = Users::UserMailer.confirmation_instructions(@user, "confirm-token-123")

    assert_equal [ @user.email ], email.to
    assert_includes html_body(email), "/users/confirmation?confirmation_token=confirm-token-123"
  end

  # Production Links
  test "links should use APP_HOST and APP_PROTOCOL" do
    with_env("APP_HOST" => "weabotalk.onrender.com", "APP_PROTOCOL" => "https") do
      email = Users::UserMailer.reset_password_instructions(@user, "reset-token-123")

      assert_includes html_body(email), "https://weabotalk.onrender.com/users/password/edit?reset_password_token=reset-token-123"
    end
  end

  private

  def with_env(values)
    original = values.keys.index_with { |key| ENV[key] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    original.each { |key, value| ENV[key] = value }
  end

  # Decoded HTML body, whether the email is multipart (HTML + text) or HTML only
  def html_body(email)
    (email.html_part || email).body.decoded
  end
end

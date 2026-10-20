require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  SIGN_UP = { user: { email: "newbie@example.com", password: "password123", password_confirmation: "password123" } }.freeze

  test "sign up should sign the user in without an email while confirmation is off" do
    assert_no_enqueued_emails do
      post user_registration_path, params: SIGN_UP
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_select "a", text: "Feed" # signed-in navbar
  end

  test "sign up should send a confirmation email while confirmation is required" do
    with_email_confirmation_required do
      assert_enqueued_emails 1 do
        post user_registration_path, params: SIGN_UP
      end

      assert_redirected_to new_user_confirmation_path
    end
  end
end

require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(email: "reader@example.com", password: "password123", password_confirmation: "password123").tap(&:confirm)
  end

  test "messages page should say it's under construction" do
    sign_in @user

    get messages_path

    assert_response :success
    assert_select "[role=status]", text: /Under construction/
    assert_select "a[href=?]", home_path, text: "Back to Feed"
  end

  test "navbar should link to feed, messages and notifications" do
    sign_in @user

    get messages_path

    assert_select "nav a[href=?]", home_path, text: "Feed"
    assert_select "nav a[href=?]", messages_path, text: "Messages"
    assert_select "nav a[href=?][title=Notifications]", notifications_path
    assert_select "nav a", text: /\AFollow(ing|ers)\z/, count: 0
  end

  test "signed out visitors should be sent to sign in" do
    get messages_path

    assert_redirected_to new_user_session_path
  end
end

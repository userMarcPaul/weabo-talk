require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # Same Accept header Turbo sends from the browser
  TURBO = { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }.freeze

  setup do
    @user = create_user("reader@example.com")
    friendship = Friendship.create!(user: create_user("friend@example.com"), friend: @user, status: "pending")
    @notification = friendship.notifications.first
  end

  test "marking as read with turbo should replace the notification and the badge" do
    sign_in @user

    patch mark_notification_as_read_path(@notification), headers: TURBO

    assert_response :success
    assert_select "turbo-stream[action=replace][target=?]", "notification_#{@notification.id}"
    assert_select "turbo-stream[action=replace][target=notifications-badge]"
    assert @notification.reload.marked_as_read?
  end

  test "deleting with turbo should remove the notification and update the badge" do
    sign_in @user

    delete notification_path(@notification), headers: TURBO

    assert_response :success
    assert_select "turbo-stream[action=remove][target=?]", "notification_#{@notification.id}"
    assert_select "turbo-stream[action=replace][target=notifications-badge]"
  end

  private

  def create_user(email)
    User.create!(email: email, password: "password123", password_confirmation: "password123").tap(&:confirm)
  end
end

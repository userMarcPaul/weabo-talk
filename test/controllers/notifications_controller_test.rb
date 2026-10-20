require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # Same Accept header Turbo sends from the browser
  TURBO = { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }.freeze

  setup do
    @user = create_user("reader@example.com")
    follow = Follow.create!(follower: create_user("fan@example.com"), followed: @user)
    @notification = follow.notifications.first
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

  test "pagination should show the current page" do
    20.times { |i| Follow.create!(follower: create_user("fan#{i}@example.com"), followed: @user) }
    sign_in @user

    get notifications_path(page: 2)

    assert_select "[id^=notification_]", count: 1
    assert_select "nav[aria-label=pagination]" do
      assert_select "[aria-current=page]", text: "2"
      assert_select "a[href=?]", notifications_path(page: 1), text: "1"
    end
  end

  private

  def create_user(email)
    User.create!(email: email, password: "password123", password_confirmation: "password123").tap(&:confirm)
  end
end

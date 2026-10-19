require "test_helper"

class FriendshipTest < ActiveSupport::TestCase
  setup do
    @sender = create_user("sender@example.com")
    @receiver = create_user("receiver@example.com")
    @friendship = Friendship.create!(user: @sender, friend: @receiver, status: "pending")
  end

  # Friend Request
  test "sending a request should notify only the receiver" do
    assert_equal [ "friend_request_sent" ], @receiver.notifications.pluck(:notification_type)
    assert_empty @sender.notifications
  end

  # Accept
  test "accepting should notify the sender only with an accepted notification" do
    assert_difference "Notification.count", 1 do
      assert @friendship.accept!
    end

    assert_equal [ "friend_request_accepted" ], @sender.notifications.pluck(:notification_type)
    assert_equal [ "friend_request_sent" ], @receiver.notifications.pluck(:notification_type)
  end

  test "accepting should make both users friends" do
    @friendship.accept!

    assert_includes @sender.friends, @receiver
    assert_includes @receiver.friends, @sender
  end

  test "accepting should work when both users sent each other a request" do
    Friendship.create!(user: @receiver, friend: @sender, status: "pending")

    assert @friendship.accept!
    assert_equal %w[accepted accepted], Friendship.order(:id).pluck(:status)
  end

  test "accepting twice should not notify again" do
    @friendship.accept!

    assert_no_difference "Notification.count" do
      assert_not @friendship.accept!
    end
  end

  # Status
  test "status predicates should match status" do
    assert @friendship.pending?
    assert_not @friendship.accepted?
  end

  private

  def create_user(email)
    User.create!(email: email, password: "password123", password_confirmation: "password123")
  end
end

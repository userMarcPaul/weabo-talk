require "test_helper"
# turbo-rails only auto-includes this once Action Cable is loaded
require "turbo/broadcastable/test_helper"

class RealTimeNotificationsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper
  include Turbo::Broadcastable::TestHelper

  setup do
    @author = create_user("author@example.com")
    @fan = create_user("fan@example.com")
    @post = @author.posts.create!(title: "Best anime", content: "Frieren")
  end

  # Subscription
  test "navbar should subscribe signed in user to their notification stream" do
    sign_in @author

    get root_path

    assert_select "turbo-cable-stream-source"
    assert_select "#notifications-badge"
    # The app bundle (Turbo + Action Cable + Stimulus) must be loaded for the stream to connect
    assert_select "script[src*='/assets/application'][type=module]"
  end

  # Broadcasts
  test "new notification should be broadcast to the recipient with the unread badge" do
    broadcasts = capture_turbo_stream_broadcasts [ @author, :notifications ] do
      perform_enqueued_jobs { @post.likes.create!(user: @fan) }
    end

    assert_equal %w[prepend replace], broadcasts.map { |stream| stream["action"] }
    assert_equal %w[notifications-list notifications-badge], broadcasts.map { |stream| stream["target"] }
    assert_includes broadcasts.first.to_html, "fan"
  end

  test "comment should create and broadcast a notification for the post author" do
    assert_turbo_stream_broadcasts [ @author, :notifications ], count: 2 do
      perform_enqueued_jobs { @post.comments.create!(user: @fan, content: "Great pick") }
    end

    assert_equal "comment_created", @author.notifications.last.notification_type
  end

  test "new follower should be broadcast to the followed user" do
    broadcasts = capture_turbo_stream_broadcasts [ @author, :notifications ] do
      perform_enqueued_jobs { Follow.create!(follower: @fan, followed: @author) }
    end

    assert_equal %w[notifications-list notifications-badge], broadcasts.map { |stream| stream["target"] }
    assert_includes broadcasts.first.to_html, "started following you"
  end

  test "undoing a like should take its notification off the page and update the badge" do
    like = @post.likes.create!(user: @fan)
    notification = like.notifications.first

    broadcasts = capture_turbo_stream_broadcasts [ @author, :notifications ] do
      perform_enqueued_jobs { like.destroy }
    end

    assert_equal %w[remove replace], broadcasts.map { |stream| stream["action"] }
    assert_equal [ "notification_#{notification.id}", "notifications-badge" ], broadcasts.map { |stream| stream["target"] }
  end

  test "unfollowing should update the followed user's badge" do
    follow = Follow.create!(follower: @fan, followed: @author)

    broadcasts = capture_turbo_stream_broadcasts [ @author, :notifications ] do
      perform_enqueued_jobs { follow.destroy }
    end

    assert_equal %w[notifications-badge], broadcasts.filter_map { |stream| stream["target"] if stream["action"] == "replace" }
  end

  test "deleting an account should not broadcast to it" do
    @post.likes.create!(user: @fan)

    assert_no_turbo_stream_broadcasts [ @author, :notifications ] do
      assert_no_enqueued_jobs { @author.destroy! }
    end
  end

  private

  def create_user(email)
    User.create!(email: email, password: "password123", password_confirmation: "password123").tap(&:confirm)
  end
end

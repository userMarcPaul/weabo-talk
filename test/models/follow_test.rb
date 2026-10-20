require "test_helper"

class FollowTest < ActiveSupport::TestCase
  setup do
    @fan = create_user("fan@example.com")
    @artist = create_user("artist@example.com")
  end

  # Following
  test "following should be one-way" do
    Follow.create!(follower: @fan, followed: @artist)

    assert_includes @fan.following, @artist
    assert_includes @artist.followers, @fan
    assert_empty @artist.following
    assert @fan.following?(@artist)
    assert_not @artist.following?(@fan)
  end

  test "following should notify only the followed user" do
    Follow.create!(follower: @fan, followed: @artist)

    assert_equal [ "new_follower" ], @artist.notifications.pluck(:notification_type)
    assert_empty @fan.notifications
  end

  test "a user should not be able to follow themselves" do
    follow = Follow.new(follower: @fan, followed: @fan)

    assert_not follow.valid?
    assert_includes follow.errors[:base], "You can't follow yourself"
  end

  test "a user should not be able to follow someone twice" do
    Follow.create!(follower: @fan, followed: @artist)

    assert_not Follow.new(follower: @fan, followed: @artist).valid?
  end

  # Unfollowing / deleting
  test "unfollowing should remove the notification" do
    follow = Follow.create!(follower: @fan, followed: @artist)

    assert_difference "Notification.count", -1 do
      follow.destroy
    end
  end

  test "deleting a user should remove their follows both ways" do
    Follow.create!(follower: @fan, followed: @artist)
    Follow.create!(follower: @artist, followed: @fan)

    assert_difference "Follow.count", -2 do
      @fan.destroy
    end
  end

  private

  def create_user(email)
    User.create!(email: email, password: "password123", password_confirmation: "password123").tap(&:confirm)
  end
end

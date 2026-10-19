require "test_helper"

class FriendshipsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @sender = create_user("sender@example.com")
    @receiver = create_user("receiver@example.com")
    @friendship = Friendship.create!(user: @sender, friend: @receiver, status: "pending")
  end

  # Decline / Cancel
  test "receiver should be able to decline a friend request" do
    sign_in @receiver

    assert_difference "Friendship.count", -1 do
      delete friendship_path(@friendship)
    end
    assert_redirected_to profile_path(@sender.profile.username)
  end

  test "declining with turbo stream should show add friend button for the sender" do
    sign_in @receiver

    # Same Accept header Turbo sends from the browser
    delete friendship_path(@friendship), headers: { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }

    assert_response :success
    assert_includes response.body, "Add Friend"
  end

  test "sender should be able to cancel a friend request" do
    sign_in @sender

    assert_difference "Friendship.count", -1 do
      delete friendship_path(@friendship)
    end
    assert_redirected_to profile_path(@receiver.profile.username)
  end

  test "other users should not be able to delete a friendship" do
    sign_in create_user("stranger@example.com")

    assert_no_difference "Friendship.count" do
      delete friendship_path(@friendship)
    end
    assert_response :not_found
  end

  private

  def create_user(email)
    User.create!(email: email, password: "password123", password_confirmation: "password123").tap(&:confirm)
  end
end

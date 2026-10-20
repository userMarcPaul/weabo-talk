require "test_helper"

class FollowsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # Same Accept header Turbo sends from the browser
  TURBO = { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }.freeze

  setup do
    @fan = create_user("fan@example.com")
    @artist = create_user("artist@example.com")
  end

  # Follow / Unfollow
  test "following with turbo should update the button and the counts" do
    sign_in @fan

    assert_difference "Follow.count", 1 do
      post follow_profile_path(@artist.profile.username), headers: TURBO
    end

    assert_response :success
    assert_select "turbo-stream[action=replace][target=?]", "follow_button_user_#{@artist.id}" do
      assert_select "template", text: /Following/
    end
    assert_select "turbo-stream[action=replace][target=?]", "follow_counts_user_#{@artist.id}" do
      assert_select "template", text: /1\s+Follower\b/
    end
  end

  test "unfollowing with turbo should show the follow button again" do
    Follow.create!(follower: @fan, followed: @artist)
    sign_in @fan

    assert_difference "Follow.count", -1 do
      delete follow_profile_path(@artist.profile.username), headers: TURBO
    end

    assert_select "turbo-stream[action=replace][target=?]", "follow_button_user_#{@artist.id}" do
      assert_select "template", text: /Follow/
      assert_select "template", text: /Following/, count: 0
    end
  end

  test "following button should unfollow without asking first" do
    Follow.create!(follower: @fan, followed: @artist)
    sign_in @fan

    get profile_path(@artist.profile.username)

    assert_select "#follow_button_user_#{@artist.id} form[action=?]", follow_profile_path(@artist.profile.username) do |form|
      assert_nil form.first["data-turbo-confirm"]
      assert_select "button", text: "✓ Following"
    end
  end

  test "following without turbo should redirect to the profile" do
    sign_in @fan

    post follow_profile_path(@artist.profile.username)

    assert_redirected_to profile_path(@artist.profile.username)
    assert_equal "You're following artist.", flash[:notice]
  end

  test "following yourself should be refused" do
    sign_in @fan

    assert_no_difference "Follow.count" do
      post follow_profile_path(@fan.profile.username)
    end
    assert_equal "You can't follow yourself", flash[:alert]
  end

  test "two follow requests at the same moment should both show the following button" do
    Follow.create!(follower: @fan, followed: @artist)
    sign_in @fan
    # The other request's follow was saved after this request's duplicate check
    Follow.define_method(:valid?) { |*| true }

    post follow_profile_path(@artist.profile.username), headers: TURBO

    assert_response :success
    assert_select "turbo-stream[target=?] template", "follow_button_user_#{@artist.id}", text: /Following/
    assert_equal 1, Follow.count
  ensure
    Follow.remove_method(:valid?)
  end

  test "signed out users should be sent to sign in to follow" do
    assert_no_difference "Follow.count" do
      post follow_profile_path(@artist.profile.username)
    end
    assert_redirected_to new_user_session_path
  end

  test "signing in from a signed out follow link should come back to the profile" do
    get profile_path(@artist.profile.username)
    assert_select "a[href=?]", follow_profile_path(@artist.profile.username), text: "Follow"

    get follow_profile_path(@artist.profile.username)
    assert_redirected_to new_user_session_path

    post user_session_path, params: { user: { email: @fan.email, password: "password123" } }
    assert_redirected_to follow_profile_path(@artist.profile.username)
    follow_redirect!
    assert_redirected_to profile_path(@artist.profile.username)
    assert_equal 0, Follow.count
  end

  # Profile
  test "profile should show the follow button and both counts" do
    Follow.create!(follower: @artist, followed: @fan)
    sign_in @fan

    get profile_path(@artist.profile.username)

    assert_select "#follow_button_user_#{@artist.id}", text: /Follow/
    assert_select "#follow_counts_user_#{@artist.id}" do
      assert_select "a[href=?]", profile_followers_path(@artist.profile.username), text: /0\s+Followers/
      assert_select "a[href=?]", profile_following_path(@artist.profile.username), text: /1\s+Following/
    end

    Follow.create!(follower: @fan, followed: @artist)
    get profile_path(@artist.profile.username)
    assert_select "#follow_counts_user_#{@artist.id}" do
      assert_select "a[href=?]", profile_followers_path(@artist.profile.username), text: /1\s+Follower\b/
      assert_select "a[href=?]", profile_following_path(@artist.profile.username), text: /1\s+Following/
    end
  end

  test "own profile should not have a follow button" do
    sign_in @fan

    get profile_path(@fan.profile.username)

    assert_select "#follow_button_user_#{@fan.id}", count: 0
  end

  # Lists
  test "followers list should show who follows the user, with follow buttons" do
    Follow.create!(follower: @fan, followed: @artist)
    sign_in @artist

    get profile_followers_path(@artist.profile.username)

    assert_response :success
    assert_select "#follow_item_user_#{@fan.id}", text: /fan/ do
      assert_select "#follow_button_user_#{@fan.id}", text: /Follow/
    end
  end

  test "long lists should be split into pages" do
    21.times { |i| Follow.create!(follower: create_user("follower#{i}@example.com"), followed: @artist) }

    get profile_followers_path(@artist.profile.username)
    assert_select "[id^=follow_item_user_]", count: 20
    assert_select "nav[aria-label=pagination]" do
      assert_select "[aria-current=page]", text: "1"
      assert_select "a[href=?]", profile_followers_path(@artist.profile.username, page: 2), text: "2"
    end

    get profile_followers_path(@artist.profile.username, page: 2)
    assert_select "[id^=follow_item_user_]", count: 1
    assert_select "[aria-current=page]", text: "2"
  end

  test "a page number past the end or not a number should still show a page" do
    Follow.create!(follower: @fan, followed: @artist)

    get profile_followers_path(@artist.profile.username, page: 99)
    assert_response :success
    assert_select "#follow_item_user_#{@fan.id}"

    get profile_followers_path(@artist.profile.username, page: "abc")
    assert_response :success
    assert_select "#follow_item_user_#{@fan.id}"
  end

  test "following list should be visible to signed out visitors" do
    Follow.create!(follower: @fan, followed: @artist)

    get profile_following_path(@fan.profile.username)

    assert_response :success
    assert_select "#follow_item_user_#{@artist.id}"
  end

  test "old friend pages should open the user's following list" do
    sign_in @fan

    get "/friendships"
    assert_redirected_to profile_following_path(@fan.profile.username)

    get "/friend-requests"
    assert_redirected_to profile_following_path(@fan.profile.username)
  end

  # Notification
  test "new follower notification should link to the follower's profile" do
    Follow.create!(follower: @fan, followed: @artist)
    sign_in @artist

    get notifications_path

    assert_select "p", text: /fan\s+started following you/
    assert_select "a[href=?]", profile_path(@fan.profile.username), text: "View Profile"
  end

  private

  def create_user(email)
    User.create!(email: email, password: "password123", password_confirmation: "password123").tap(&:confirm)
  end
end

require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = create_user("owner@example.com")
  end

  # Privacy
  test "email should not be shown to signed out visitors" do
    get profile_path(@owner.profile.username)

    assert_response :success
    assert_not_includes response.body, @owner.email
  end

  test "email should not be shown to other users" do
    sign_in create_user("visitor@example.com")

    get profile_path(@owner.profile.username)

    assert_not_includes response.body, @owner.email
  end

  test "email should be shown to the owner" do
    sign_in @owner

    get profile_path(@owner.profile.username)

    assert_includes response.body, @owner.email
  end

  test "email verified badge should only be shown for confirmed accounts" do
    unconfirmed = User.create!(email: "pending@example.com", password: "password123", password_confirmation: "password123")

    get profile_path(@owner.profile.username)
    assert_includes response.body, "<span>Email verified</span>"

    get profile_path(unconfirmed.profile.username)
    assert_not_includes response.body, "<span>Email verified</span>"
  end

  # Images
  test "profile avatar should be shown as a smaller version" do
    @owner.profile.update!(avatar: image_upload(width: 1000, height: 1000))

    get profile_path(@owner.profile.username)

    assert_select "img[alt=Avatar][src*='/rails/active_storage/representations/']"
  end

  test "too big avatar upload should show the error instead of crashing" do
    sign_in @owner

    patch profile_path(@owner.profile.username), params: { profile: { avatar: image_upload_param(width: 2600, height: 1800, format: "png", content_type: "image/png") } }

    assert_response :unprocessable_entity
    assert_includes response.body, "Avatar file size must be less than 5MB"
  end

  # Update
  test "failed username change should keep the form on the saved username" do
    taken = create_user("taken@example.com").profile.username
    sign_in @owner

    patch profile_path(@owner.profile.username), params: { profile: { username: taken } }

    assert_response :unprocessable_entity
    assert_select "form[action=?]", profile_path(@owner.profile.username)
  end

  private

  def create_user(email)
    User.create!(email: email, password: "password123", password_confirmation: "password123").tap(&:confirm)
  end
end

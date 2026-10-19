require "test_helper"

class DraftPrivacyTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @author = create_user("author@example.com")
    @stranger = create_user("stranger@example.com")
    @draft = @author.posts.create!(title: "Secret draft", content: "Unfinished draft content", status: :draft)
    @published = @author.posts.create!(title: "Public post", content: "Published post content")
  end

  # Post Page
  test "author should be able to view their own draft" do
    sign_in @author

    get post_path(@draft)

    assert_response :success
  end

  test "other users should not be able to view a draft" do
    sign_in @stranger

    get post_path(@draft)

    assert_response :not_found
  end

  test "signed out visitors should not be able to view a draft" do
    get post_path(@draft)

    assert_response :not_found
  end

  test "anyone should be able to view a published post" do
    get post_path(@published)

    assert_response :success
  end

  # Profile Page
  test "profile should not list drafts" do
    sign_in @stranger

    get profile_path(@author.profile.username)

    assert_response :success
    assert_includes response.body, "Published post content"
    assert_not_includes response.body, "Unfinished draft content"
  end

  # Interactions
  test "other users should not be able to like a draft" do
    sign_in @stranger

    assert_no_difference "Like.count" do
      post post_likes_path(@draft), as: :turbo_stream
    end
    assert_response :not_found
  end

  test "other users should not be able to react to a draft" do
    sign_in @stranger

    assert_no_difference "Reaction.count" do
      post post_reactions_path(@draft), params: { reaction: { reaction_type: "🔥" } }, as: :turbo_stream
    end
    assert_response :not_found
  end

  test "other users should not be able to comment on a draft" do
    sign_in @stranger

    assert_no_difference "Comment.count" do
      post post_comments_path(@draft), params: { comment: { content: "Nice" } }, as: :turbo_stream
    end
    assert_response :not_found
  end

  private

  def create_user(email)
    User.create!(email: email, password: "password123", password_confirmation: "password123").tap(&:confirm)
  end
end

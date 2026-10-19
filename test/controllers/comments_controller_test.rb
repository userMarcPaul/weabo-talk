require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(email: "commenter@example.com", password: "password123", password_confirmation: "password123").tap(&:confirm)
    @post = @user.posts.create!(title: "Best anime", content: "Frieren")
  end

  # HTML Fallback
  test "invalid comment without turbo should redirect to the post with an error" do
    sign_in @user

    assert_no_difference "Comment.count" do
      post post_comments_path(@post), params: { comment: { content: "" } }
    end

    assert_redirected_to post_path(@post)
    assert_includes flash[:alert], "Content can't be blank"
  end
end

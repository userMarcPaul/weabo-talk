require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @author = User.create!(email: "author@example.com", password: "password123", password_confirmation: "password123").tap(&:confirm)
  end

  # Publish
  test "publishing a draft should redirect home" do
    draft = @author.posts.create!(title: "My draft", content: "Almost done", status: :draft)
    sign_in @author

    patch publish_post_path(draft)

    assert_redirected_to home_path
    assert draft.reload.published?
  end

  test "publishing a post that isn't a draft should redirect to drafts with an error" do
    published = @author.posts.create!(title: "Already out", content: "Published")
    sign_in @author

    patch publish_post_path(published)

    assert_redirected_to drafts_posts_path
    assert_equal "Draft not found", flash[:alert]
  end
end

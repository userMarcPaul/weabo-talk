require "test_helper"

class LikesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # Same Accept header Turbo sends from the browser
  TURBO = { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }.freeze

  setup do
    @author = User.create!(email: "author@example.com", password: "password123", password_confirmation: "password123").tap(&:confirm)
    @fan = User.create!(email: "fan@example.com", password: "password123", password_confirmation: "password123").tap(&:confirm)
    @post = @author.posts.create!(title: "Best anime", content: "Frieren")
  end

  # Counts update in place
  test "liking should update the like button and the counts" do
    sign_in @fan

    post post_likes_path(@post), headers: TURBO

    assert_response :success
    assert_select "turbo-stream[action=replace][target=?]", "like_post_#{@post.id}"
    assert_select "turbo-stream[action=replace][target=?]", "stats_post_#{@post.id}" do
      assert_select "template", text: /1\s+likes/
    end
  end

  test "unliking should update the counts" do
    like = @post.likes.create!(user: @fan)
    sign_in @fan

    delete post_like_path(@post, like), headers: TURBO

    assert_select "turbo-stream[action=replace][target=?]", "stats_post_#{@post.id}" do
      assert_select "template", text: /0\s+likes/
    end
  end
end

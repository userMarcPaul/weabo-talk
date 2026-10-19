require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(email: "reader@example.com", password: "password123", password_confirmation: "password123").tap(&:confirm)
  end

  # Same Accept header Turbo sends, also when it follows a redirect after a form submission
  TURBO = { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }.freeze

  # Flash (rendered by the application layout)
  test "flash messages should be shown on the home page" do
    sign_in @user

    post posts_path, params: { post: { title: "New post", content: "Hello" } }
    follow_redirect!

    assert_includes response.body, "Post was successfully created."
  end

  test "home should render the page for Turbo requests" do
    sign_in @user

    # e.g. the redirect after signing in or deleting a post
    get home_path, headers: TURBO

    assert_equal "text/html", response.media_type
  end

  # Load More
  test "home feed should link to the next page when there are more posts" do
    21.times { |i| @user.posts.create!(title: "Post #{i}", content: "x") }
    sign_in @user

    get home_path

    assert_select "#load-more a[href=?][data-turbo-stream]", home_feed_path(page: 2)
  end

  test "home feed should not show load more on the last page" do
    @user.posts.create!(title: "Only post", content: "x")
    sign_in @user

    get home_path

    assert_select "#load-more a", count: 0
  end

  test "load more should append the next page and replace the button" do
    21.times { |i| @user.posts.create!(title: "Post #{i}", content: "x") }
    sign_in @user

    get home_feed_path(page: 2), headers: TURBO

    assert_response :success
    assert_select "turbo-stream[action=append][target=posts-feed]"
    assert_select "turbo-stream[action=replace][target=load-more]"
    assert_includes response.body, "Post 0" # the oldest post is on page 2
  end
end

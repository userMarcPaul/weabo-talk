require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(email: "commenter@example.com", password: "password123", password_confirmation: "password123").tap(&:confirm)
    @post = @user.posts.create!(title: "Best anime", content: "Frieren")
  end

  # Turbo Streams (same Accept header Turbo sends from the browser)
  TURBO = { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }.freeze

  test "comment with turbo should be added to the comment list and reset the form" do
    sign_in @user

    post post_comments_path(@post), params: { comment: { content: "Great pick" } }, headers: TURBO

    assert_response :success
    assert_select "turbo-stream[action=prepend][target=?]", "comments-#{@post.id}"
    assert_select "turbo-stream[action=replace][target=?]", "comment-form-#{@post.id}"
    assert_select "turbo-stream[action=remove][target=?]", "no-comments-#{@post.id}"
    assert_select "turbo-stream[action=replace][target=?]", "stats_post_#{@post.id}" do
      assert_select "template", text: /1\s+comments/
    end
    assert_includes response.body, "Great pick"
  end

  test "deleting a comment with turbo should remove it and update the counts" do
    comment = @post.comments.create!(user: @user, content: "Remove me")
    sign_in @user

    delete post_comment_path(@post, comment), headers: TURBO

    assert_response :success
    assert_select "turbo-stream[action=remove][target=?]", "comment-#{comment.id}"
    assert_select "turbo-stream[action=replace][target=?]", "stats_post_#{@post.id}" do
      assert_select "template", text: /0\s+comments/
    end
    assert_not Comment.exists?(comment.id)
  end

  test "reply with turbo should be added under its parent comment" do
    parent = @post.comments.create!(user: @user, content: "First!")
    sign_in @user

    post post_comments_path(@post), params: { comment: { content: "Agreed", parent_comment_id: parent.id } }, headers: TURBO

    assert_response :success
    assert_select "turbo-stream[action=append][target=?]", "replies-#{parent.id}"
    assert_select "turbo-stream[target=?]", "comments-#{@post.id}", count: 0
  end

  test "invalid comment with turbo should show the error in the form" do
    sign_in @user

    post post_comments_path(@post), params: { comment: { content: "" } }, headers: TURBO

    assert_response :unprocessable_entity
    assert_select "turbo-stream[action=replace][target=?]", "comment-form-#{@post.id}"
    assert_includes response.body, "prevented your comment from being saved"
  end

  test "reply to a comment on another post should be rejected" do
    other_post = @user.posts.create!(title: "Other anime", content: "Dandadan")
    other_comment = other_post.comments.create!(user: @user, content: "On the other post")
    sign_in @user

    assert_no_difference "Comment.count" do
      post post_comments_path(@post), params: { comment: { content: "Sneaky", parent_comment_id: other_comment.id } }
    end
    assert_includes flash[:alert], "Parent comment must be on the same post"
  end

  # Display
  test "comment HTML should be shown as text, with URLs still linked" do
    @post.comments.create!(user: @user, content: %(<img src="https://evil.example/x.png"> see https://example.com/a?b=1&c=2))
    sign_in @user

    get post_path(@post)

    assert_select "img[src='https://evil.example/x.png']", count: 0
    assert_includes response.body, "&lt;img"
    assert_select "a[href=?][target=_blank]", "https://example.com/a?b=1&c=2"
  end

  test "delete comment should ask for confirmation" do
    comment = @post.comments.create!(user: @user, content: "Mine")
    sign_in @user

    get post_path(@post)

    assert_select "form[action=?][data-turbo-confirm]", post_comment_path(@post, comment)
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

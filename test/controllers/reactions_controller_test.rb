require "test_helper"

class ReactionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # Same Accept header Turbo sends from the browser
  TURBO = { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }.freeze

  setup do
    @owner = create_user("owner@example.com")
    @post = @owner.posts.create!(title: "Best anime", content: "Frieren")
    @reaction = @post.reactions.create!(user: @owner, reaction_type: "🔥")
  end

  # Delete
  test "owner should be able to delete their reaction" do
    sign_in @owner

    assert_difference "Reaction.count", -1 do
      # Same Accept header Turbo sends from the browser
      delete post_reaction_path(@post, @reaction), headers: { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }
    end
    assert_response :success
  end

  test "other users should not be able to delete someone else's reaction" do
    sign_in create_user("stranger@example.com")

    assert_no_difference "Reaction.count" do
      delete post_reaction_path(@post, @reaction), as: :turbo_stream
    end
    assert_response :not_found
  end

  # One reaction per user (setup: the owner reacted 🔥)
  test "another user's reaction should be added and update the counts" do
    sign_in create_user("fan@example.com")

    assert_difference "Reaction.count", 1 do
      post post_reactions_path(@post), params: { reaction: { reaction_type: "😂" } }, headers: TURBO
    end

    assert_response :success
    assert_select "turbo-stream[action=replace][target=?]", "stats_post_#{@post.id}" do
      assert_select "template", text: /2\s+reactions/
    end
  end

  test "picking another emoji should switch the user's reaction" do
    sign_in @owner

    assert_no_difference "Reaction.count" do
      post post_reactions_path(@post), params: { reaction: { reaction_type: "😂" } }, headers: TURBO
    end

    assert_equal "😂", @reaction.reload.reaction_type
    assert_select "turbo-stream[action=replace][target=?]", "reaction_post_#{@post.id}" do
      assert_select "template", text: /😂 Reacted/
    end
  end

  test "picking the same emoji again should remove the user's reaction" do
    sign_in @owner

    assert_difference "Reaction.count", -1 do
      post post_reactions_path(@post), params: { reaction: { reaction_type: "🔥" } }, headers: TURBO
    end

    assert_select "turbo-stream[action=replace][target=?]", "reaction_post_#{@post.id}" do
      assert_select "template", text: /😊 React/
    end
  end

  # Display
  test "react button should show the user's reaction and the counts should show the emojis" do
    @post.reactions.create!(user: create_user("fan1@example.com"), reaction_type: "😂")
    @post.reactions.create!(user: create_user("fan2@example.com"), reaction_type: "😂")
    sign_in @owner

    get post_path(@post)

    assert_select "#reaction_post_#{@post.id} button[type=button]", text: "🔥 Reacted"
    # Most used first: 😂 x2, then 🔥 x1
    assert_select "#stats_post_#{@post.id}", text: /😂\s*2\s*🔥\s*1\s*3\s+reactions/
  end

  # Picker
  test "picker should only offer reactions the model accepts" do
    sign_in @owner

    get post_path(@post)

    offered = css_select("input[name='reaction[reaction_type]']").map { |input| input["value"] }
    assert_equal Reaction::ALLOWED_REACTIONS, offered
  end

  test "signed out users should get a react link that leaves the frame" do
    get post_path(@post)

    assert_select "a[href=?][data-turbo-frame=_top]", user_session_path, text: "😊 React"
    assert_select "a[href=?][data-turbo-frame=_top]", user_session_path, text: "🤍 Like"
  end

  # HTML Fallback
  test "reacting without turbo should redirect to the post" do
    sign_in @owner

    post post_reactions_path(@post), params: { reaction: { reaction_type: "😂" } }

    assert_redirected_to post_path(@post)
  end

  private

  def create_user(email)
    User.create!(email: email, password: "password123", password_confirmation: "password123").tap(&:confirm)
  end
end

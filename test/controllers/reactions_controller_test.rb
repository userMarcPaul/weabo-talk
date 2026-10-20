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
  test "react button should show the user's reaction and the counts only the total" do
    @post.reactions.create!(user: create_user("fan1@example.com"), reaction_type: "😂")
    sign_in @owner

    get post_path(@post)

    assert_select "#reaction_post_#{@post.id} details[data-controller=dropdown] summary", text: "🔥 Reacted"
    assert_select "#stats_post_#{@post.id}" do
      assert_select "summary", text: /2\s+reactions/
      assert_select "turbo-frame#reactions_card_post_#{@post.id}[src=?][loading=lazy]", post_reactions_path(@post)
      # The per-emoji list is only in the card
      assert_select "summary", text: /😂|🔥/, count: 0
    end
  end

  test "counts should not have a reactions card when there are no reactions" do
    @reaction.destroy
    sign_in @owner

    get post_path(@post)

    assert_select "#stats_post_#{@post.id}", text: /0\s+reactions/
    assert_select "#stats_post_#{@post.id} details", count: 0
  end

  # Reactions card
  test "reactions card should list each emoji with its count and who reacted, most used first" do
    @post.reactions.create!(user: create_user("fan1@example.com"), reaction_type: "😂")
    @post.reactions.create!(user: create_user("fan2@example.com"), reaction_type: "😂")

    # Signed out visitors can open it too
    get post_reactions_path(@post), headers: { "Turbo-Frame" => "reactions_card_post_#{@post.id}" }

    assert_response :success
    assert_select "turbo-frame#reactions_card_post_#{@post.id} li", count: 2
    rows = css_select("turbo-frame#reactions_card_post_#{@post.id} li").map { |li| li.text.squish }
    assert_equal "😂 2 fan1, fan2", rows.first
    assert_equal "🔥 1 owner", rows.second
  end

  test "reactions card should not be available for someone else's draft" do
    draft = @owner.posts.create!(title: "Secret", content: "Draft", status: :draft)
    sign_in create_user("stranger@example.com")

    get post_reactions_path(draft)

    assert_response :not_found
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

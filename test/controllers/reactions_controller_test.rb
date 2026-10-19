require "test_helper"

class ReactionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

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

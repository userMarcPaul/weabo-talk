require "test_helper"

class ReactionTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "reactor@example.com", password: "password123", password_confirmation: "password123").tap(&:confirm)
    @post = @user.posts.create!(title: "Best anime", content: "Frieren")
  end

  test "a user should have only one reaction per post" do
    @post.reactions.create!(user: @user, reaction_type: "🔥")

    second = @post.reactions.build(user: @user, reaction_type: "😂")

    assert_not second.valid?
    assert_includes second.errors[:user_id], "can react to a post only once"
  end

  test "the same user can react to different posts" do
    other_post = @user.posts.create!(title: "Other anime", content: "Dandadan")
    @post.reactions.create!(user: @user, reaction_type: "🔥")

    assert other_post.reactions.build(user: @user, reaction_type: "🔥").valid?
  end
end

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

  # Drafts (form posts to save_draft with post[id])
  test "edit form for a draft should send the draft id as post[id]" do
    draft = @author.posts.create!(title: "My draft", content: "Almost done", status: :draft)
    sign_in @author

    get edit_post_path(draft)

    assert_select "form[action=?]", save_draft_post_path do
      assert_select "input[type=hidden][name='post[id]'][value=?]", draft.id.to_s
    end
  end

  test "saving an existing draft should update it instead of creating a new post" do
    draft = @author.posts.create!(title: "My draft", content: "Almost done", status: :draft)
    sign_in @author

    assert_no_difference "Post.count" do
      post save_draft_post_path, params: { action_type: "save", post: { id: draft.id, title: "My draft v2", content: "Done" } }
    end
    assert_equal "My draft v2", draft.reload.title
    assert draft.draft?
  end

  test "publishing an existing draft from the form should keep the edits" do
    draft = @author.posts.create!(title: "My draft", content: "Almost done", status: :draft)
    sign_in @author

    assert_no_difference "Post.count" do
      post save_draft_post_path, params: { action_type: "publish", post: { id: draft.id, title: "Final title", content: "Final content" } }
    end
    draft.reload
    assert draft.published?
    assert_equal "Final title", draft.title
  end

  # Published posts
  test "edit form for a published post should update it in place" do
    published = @author.posts.create!(title: "Already out", content: "Published")
    sign_in @author

    get edit_post_path(published)

    assert_select "form[action=?]", post_path(published) do
      assert_select "input[name=_method][value=patch]"
      assert_select "input[type=submit][value=?]", "Save Changes"
    end
  end

  test "removing an existing image should delete it" do
    published = @author.posts.create!(title: "With image", content: "Pic")
    image = published.post_images.create!(image: { io: StringIO.new(png_data), filename: "a.png", content_type: "image/png" })
    sign_in @author

    patch post_path(published), params: { post: { post_images_attributes: { "0" => { id: image.id, _destroy: "1" } } } }

    assert_redirected_to post_path(published)
    assert_empty published.reload.post_images
  end

  # Feed
  test "post titles should be shown in the feed" do
    @author.posts.create!(title: "Frieren is peak", content: "Agree?")
    sign_in @author

    get root_path

    assert_select "h3 a", text: "Frieren is peak"
  end

  test "publishing a post that isn't a draft should redirect to drafts with an error" do
    published = @author.posts.create!(title: "Already out", content: "Published")
    sign_in @author

    patch publish_post_path(published)

    assert_redirected_to drafts_posts_path
    assert_equal "Draft not found", flash[:alert]
  end

  private

  # Smallest valid PNG (1x1 transparent pixel)
  def png_data
    Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")
  end
end

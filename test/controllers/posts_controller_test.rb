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

  # Live validation
  test "post form should pass the validation url to the validation controller" do
    sign_in @author

    get new_post_path

    assert_select "[data-controller~='post-form-validation'][data-post-form-validation-validation-url-value=?]", validate_form_path
  end

  test "new post buttons should show their label and send the action type" do
    sign_in @author

    get new_post_path

    assert_select "button[type=submit][name=action_type][value=publish]", text: "Publish"
    assert_select "button[type=submit][name=action_type][value=save]", text: "Save"
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

  test "saving a draft with errors should show the form again with the edits" do
    draft = @author.posts.create!(title: "My draft", content: "Almost done", status: :draft)
    sign_in @author

    post save_draft_post_path, params: { action_type: "save", post: { id: draft.id, title: "ab", content: "Kept edit" } }

    assert_response :unprocessable_entity
    assert_includes response.body, "Title is too short"
    assert_select "textarea[name='post[content]']", text: "Kept edit"
    assert_equal "My draft", draft.reload.title
  end

  test "saving a draft with the id of a published post should not create a new draft" do
    published = @author.posts.create!(title: "Already out", content: "Published")
    sign_in @author

    assert_no_difference "Post.count" do
      post save_draft_post_path, params: { action_type: "save", post: { id: published.id, title: "Hijack", content: "x" } }
    end
    assert_redirected_to drafts_posts_path
    assert_equal "Draft not found", flash[:alert]
    assert_equal "Already out", published.reload.title
  end

  test "drafts page cards should have an id and a delete confirmation" do
    draft = @author.posts.create!(title: "My draft", content: "Almost done", status: :draft)
    sign_in @author

    get drafts_posts_path

    assert_select "##{ActionView::RecordIdentifier.dom_id(draft)}"
    assert_select "form[action=?][data-turbo-confirm]", post_path(draft)
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

  # Delete (same Accept header Turbo sends from the browser)
  TURBO = { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }.freeze

  test "deleting a post from its own page should go to the feed" do
    published = @author.posts.create!(title: "Already out", content: "Published")
    sign_in @author

    delete post_path(published), headers: TURBO.merge("Referer" => post_url(published))

    assert_redirected_to home_path
    assert_response :see_other
    assert_not Post.exists?(published.id)
  end

  test "deleting a post from a list should remove it from the page" do
    published = @author.posts.create!(title: "Already out", content: "Published")
    sign_in @author

    delete post_path(published), headers: TURBO.merge("Referer" => home_url)

    assert_response :success
    assert_select "turbo-stream[action=remove][target=?]", ActionView::RecordIdentifier.dom_id(published)
  end

  # Feed
  test "comment button in the feed should open the post page, not load inside its frame" do
    @author.posts.create!(title: "Frieren is peak", content: "Agree?")
    sign_in @author

    get root_path

    assert_select "a[data-turbo-frame=_top]", text: "💬 Comment"
  end

  test "feed post counts should not run a query per post" do
    3.times { |i| @author.posts.create!(title: "Feed post #{i}", content: "x") }
    sign_in @author

    count_queries = []
    counter = ->(*, payload) { count_queries << payload[:sql] if payload[:sql].include?("COUNT") }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { get root_path }

    # Only the pagination count
    assert_equal 1, count_queries.size, count_queries.join("\n")
  end

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

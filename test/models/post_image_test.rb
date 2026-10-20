require "test_helper"

class PostImageTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email: "photos@example.com", password: "password123", password_confirmation: "password123")
    @post = user.posts.create!(title: "Photos", content: "Look")
  end

  # Display version (actually generated, not just its URL)
  test "display version should be a WebP that fits 1200x1200" do
    post_image = @post.post_images.create!(image: image_upload(width: 3000, height: 2000))

    variant = post_image.image_for_display.processed

    assert_equal "image/webp", variant.image.blob.content_type
    assert_equal [ 1200, 800 ], variant.image.blob.open { |file| image_dimensions(file) }
  end

  test "image over 10MB should be rejected" do
    post_image = @post.post_images.build(image: image_upload(width: 2600, height: 1800, format: "png", content_type: "image/png"))

    assert_not post_image.valid?
    assert_includes post_image.errors[:image], "file size must be less than 10MB"
  end
end

require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  setup do
    @profile = User.create!(email: "pics@example.com", password: "password123", password_confirmation: "password123").profile
  end

  # Shrinking
  test "uploaded avatar and banner should be stored as smaller WebP" do
    @profile.update!(avatar: image_upload(width: 2000, height: 2000), banner: image_upload(width: 4000, height: 1500))

    assert_equal "image/webp", @profile.avatar.content_type
    assert_equal [ 800, 800 ], @profile.avatar.blob.open { |file| image_dimensions(file) }
    assert_equal "image/webp", @profile.banner.content_type
    assert_equal [ 2000, 750 ], @profile.banner.blob.open { |file| image_dimensions(file) }
  end

  # Banner limits
  test "banner over 10MB should be rejected" do
    @profile.banner = image_upload(width: 2600, height: 1800, format: "png", content_type: "image/png")

    assert_operator @profile.banner.byte_size, :>, Profile::BANNER_MAX_SIZE
    assert_not @profile.valid?
    assert_includes @profile.errors[:banner], "file size must be less than 10MB"
  end

  test "banner that isn't an image should be rejected" do
    @profile.banner = { io: StringIO.new("%PDF-1.4 not an image"), filename: "doc.pdf", content_type: "application/pdf" }

    assert_not @profile.valid?
    assert_includes @profile.errors[:banner], "must be a valid image format (JPEG, PNG, GIF, or WebP)"
  end
end

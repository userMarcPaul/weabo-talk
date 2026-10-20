require "test_helper"

class Images::UploadShrinkerTest < ActiveSupport::TestCase
  test "large photo should be resized and converted to WebP" do
    upload = image_upload(width: 3000, height: 2000)

    result = Images::UploadShrinker.call(upload, max_bytes: 10.megabytes, max_dimensions: [ 1600, 1600 ])

    assert_equal "image/webp", result[:content_type]
    assert_equal "photo.webp", result[:filename]
    assert_equal [ 1600, 1067 ], image_dimensions(result[:io])
    assert_operator result[:io].size, :<, upload.size
  end

  test "image that would get bigger as WebP should be kept as it is" do
    # Already a heavily compressed WebP: re-saving at normal quality makes it bigger
    upload = image_upload(width: 400, height: 400, format: "webp", content_type: "image/webp", quality: 5)

    assert_same upload, Images::UploadShrinker.call(upload, max_bytes: 10.megabytes, max_dimensions: [ 1600, 1600 ])
  end

  test "file over the size limit should be kept so the validation rejects it" do
    upload = image_upload(width: 3000, height: 2000)

    assert_same upload, Images::UploadShrinker.call(upload, max_bytes: 1.kilobyte, max_dimensions: [ 1600, 1600 ])
  end

  test "GIF should be kept so animations keep playing" do
    upload = image_upload(width: 2000, height: 2000, format: "gif", content_type: "image/gif")

    assert_same upload, Images::UploadShrinker.call(upload, max_bytes: 10.megabytes, max_dimensions: [ 1600, 1600 ])
  end

  test "file that isn't a readable image should be kept so the validation decides" do
    file = Tempfile.new([ "fake", ".jpg" ]).tap { |f| f.write("not an image"); f.rewind }
    upload = ActionDispatch::Http::UploadedFile.new(tempfile: file, filename: "fake.jpg", type: "image/jpeg")

    assert_same upload, Images::UploadShrinker.call(upload, max_bytes: 10.megabytes, max_dimensions: [ 1600, 1600 ])
  end
end

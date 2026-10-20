# Builds image uploads for tests (libvips is already needed for Active Storage variants)
module ImageFiles
  # The upload a controller receives (ActionDispatch::Http::UploadedFile), for model and service tests
  def image_upload(**options)
    path, filename, content_type = write_image(**options)
    tempfile = Tempfile.new([ "upload", File.extname(path) ], binmode: true).tap { |file| file.write(File.binread(path)); file.rewind }
    ActionDispatch::Http::UploadedFile.new(tempfile: tempfile, filename: filename, type: content_type)
  end

  # The file to send in a request test (Rails turns it into an UploadedFile on the server)
  def image_upload_param(**options)
    path, filename, content_type = write_image(**options)
    Rack::Test::UploadedFile.new(path, content_type, true, original_filename: filename)
  end

  def image_dimensions(io)
    image = io.respond_to?(:path) ? Vips::Image.new_from_file(io.path) : Vips::Image.new_from_buffer(io.read, "")
    [ image.width, image.height ]
  end

  private

  # noise: photo-like content that compresses badly (big files); quality: for jpg/webp
  def write_image(width:, height:, format: "jpg", content_type: "image/jpeg", noise: true, quality: nil)
    band = -> { noise ? Vips::Image.gaussnoise(width, height, mean: 128, sigma: 40).cast(:uchar) : Vips::Image.black(width, height).add(90).cast(:uchar) }
    image = band.call.bandjoin([ band.call, band.call ])

    path = File.join(Dir.mktmpdir, "photo.#{format}")
    quality ? image.write_to_file(path, Q: quality) : image.write_to_file(path)
    [ path, "photo.#{format}", content_type ]
  end
end

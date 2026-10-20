# frozen_string_literal: true

module Images
  # Shrinks an uploaded image before Active Storage stores it: resized to fit within
  # max_dimensions, converted to WebP and stripped of metadata (e.g. GPS location).
  # Anything it can't or shouldn't shrink is returned unchanged, so the model's
  # validations still decide: files over max_bytes, other content types, GIFs (they'd
  # lose their animation) and images it can't read.
  class UploadShrinker
    SHRINKABLE_TYPES = %w[image/jpeg image/png image/webp].freeze
    QUALITY = 80

    def self.call(attachable, max_bytes:, max_dimensions:)
      new(attachable, max_bytes:, max_dimensions:).call
    end

    def initialize(attachable, max_bytes:, max_dimensions:)
      @attachable = attachable
      @max_bytes = max_bytes
      @max_dimensions = max_dimensions
    end

    def call
      return @attachable unless shrinkable?

      shrunk = ImageProcessing::Vips
        .source(@attachable.tempfile.path)
        .resize_to_limit(*@max_dimensions)
        .convert("webp")
        .saver(quality: QUALITY, strip: true)
        .call

      # Keep the original if it was already smaller (e.g. a small, well-compressed image)
      return @attachable if shrunk.size >= @attachable.size

      { io: shrunk, filename: "#{File.basename(@attachable.original_filename, ".*")}.webp", content_type: "image/webp" }
    rescue Vips::Error, ImageProcessing::Error
      @attachable
    end

    private

    # Only form uploads (the file the browser sent), in a type we convert, within the size limit
    def shrinkable?
      @attachable.is_a?(ActionDispatch::Http::UploadedFile) &&
        SHRINKABLE_TYPES.include?(@attachable.content_type) &&
        @attachable.size <= @max_bytes
    end
  end
end

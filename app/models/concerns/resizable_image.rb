# frozen_string_literal: true

# Keeps uploaded images small for storage (Supabase free tier: 1 GB) and for pages:
#
#   resizable_image :avatar, max_bytes: 5.megabytes, upload: [ 800, 800 ], display: [ 400, 400 ]
#
# - Uploads are shrunk to fit `upload` and converted to WebP before they're stored
#   (Images::UploadShrinker). Files over max_bytes are left as they are, so the size
#   validation rejects them.
# - `avatar_for_display` is a WebP variant that fits `display`, made the first time it's
#   requested. GIFs are shown as they are, so animations keep playing.
module ResizableImage
  extend ActiveSupport::Concern

  DISPLAY_QUALITY = 80

  class_methods do
    def resizable_image(name, max_bytes:, upload:, display:)
      define_method("#{name}=") do |attachable|
        super(Images::UploadShrinker.call(attachable, max_bytes: max_bytes, max_dimensions: upload))
      end

      define_method("#{name}_for_display") do
        attachment = public_send(name)
        return attachment unless attachment.variable? && attachment.content_type != "image/gif"

        attachment.variant(resize_to_limit: display, format: :webp, saver: { quality: DISPLAY_QUALITY, strip: true })
      end
    end
  end
end

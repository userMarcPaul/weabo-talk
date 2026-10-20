# frozen_string_literal: true

class Profile < ApplicationRecord
  include ResizableImage

  IMAGE_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  AVATAR_MAX_SIZE = 5.megabytes
  BANNER_MAX_SIZE = 10.megabytes

  belongs_to :user, dependent: :destroy
  has_one_attached :avatar, dependent: :purge
  has_one_attached :banner, dependent: :purge

  # Shrunk on upload and shown as smaller WebP (see ResizableImage)
  resizable_image :avatar, max_bytes: AVATAR_MAX_SIZE, upload: [ 800, 800 ], display: [ 400, 400 ]
  resizable_image :banner, max_bytes: BANNER_MAX_SIZE, upload: [ 2000, 2000 ], display: [ 1600, 1600 ]

  # Validations
  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 30 }
  validates :username, format: { with: /\A[a-zA-Z0-9_]+\z/, message: "can only contain letters, numbers, and underscores" }
  validates :bio, length: { maximum: 500 }, allow_blank: true
  validates :user_id, presence: true

  # Scopes
  scope :with_avatar, -> { where.associated(:avatar_attachment) }
  scope :with_banner, -> { where.associated(:banner_attachment) }

  # Avatar and banner validation
  validate :avatar_file_size
  validate :avatar_file_type
  validate :banner_file_size
  validate :banner_file_type

  private

  def avatar_file_size
    return unless avatar.attached?
    if avatar.byte_size > AVATAR_MAX_SIZE
      errors.add(:avatar, "file size must be less than 5MB")
    end
  end

  def avatar_file_type
    return unless avatar.attached?
    unless avatar.content_type.in?(IMAGE_TYPES)
      errors.add(:avatar, "must be a valid image format (JPEG, PNG, GIF, or WebP)")
    end
  end

  def banner_file_size
    return unless banner.attached?
    if banner.byte_size > BANNER_MAX_SIZE
      errors.add(:banner, "file size must be less than 10MB")
    end
  end

  def banner_file_type
    return unless banner.attached?
    unless banner.content_type.in?(IMAGE_TYPES)
      errors.add(:banner, "must be a valid image format (JPEG, PNG, GIF, or WebP)")
    end
  end
end

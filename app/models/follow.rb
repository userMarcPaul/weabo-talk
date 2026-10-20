# frozen_string_literal: true

# One-way follow: follower follows followed (no request, nothing to accept)
class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"
  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :follower_id, uniqueness: { scope: :followed_id, message: "already follows this user" }
  validate :cannot_follow_self

  after_create :notify_followed

  private

  def cannot_follow_self
    errors.add(:base, "You can't follow yourself") if follower_id == followed_id
  end

  def notify_followed
    Notification.create!(
      user: followed,
      notification_type: "new_follower",
      notifiable: self
    )
  end
end

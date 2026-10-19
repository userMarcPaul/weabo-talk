# frozen_string_literal: true

class Friendship < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: "User", foreign_key: "friend_id"
  has_many :notifications, as: :notifiable, dependent: :destroy

  STATUSES = %w[pending accepted blocked].freeze

  validates :user_id, presence: true
  validates :friend_id, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :friend_id, message: "can only have one friendship request per user" }
  validate :user_cannot_friend_self

  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }
  scope :blocked, -> { where(status: "blocked") }
  # Friendships the user sent or received
  scope :involving, ->(user) { where(user: user).or(where(friend: user)) }

  # Only real requests notify; the accepted reverse friendship is created silently
  after_create :notify_friend_request, if: :pending?
  after_destroy :cleanup_notifications, :destroy_reverse_friendship

  def pending?
    status == "pending"
  end

  def accepted?
    status == "accepted"
  end

  # Accept a pending request: both directions become accepted and the sender is notified.
  # Returns false if the request isn't pending (e.g. already accepted).
  def accept!
    return false unless pending?

    transaction do
      update!(status: "accepted")
      accept_reverse_friendship!
      notify_acceptance
    end
    true
  end

  def reject!
    destroy
  end

  def block!
    update(status: "blocked")
  end

  private

  def user_cannot_friend_self
    errors.add(:friend_id, "cannot add yourself as a friend") if user_id == friend_id
  end

  def notify_friend_request
    Notification.create!(
      user: friend,
      notification_type: "friend_request_sent",
      notifiable: self
    )
  end

  def notify_acceptance
    Notification.create!(
      user: user,
      notification_type: "friend_request_accepted",
      notifiable: self
    )
  end

  # The reverse friendship may already exist as a pending request from the other user
  def accept_reverse_friendship!
    Friendship.find_or_initialize_by(user_id: friend_id, friend_id: user_id).update!(status: "accepted")
  end

  def cleanup_notifications
    notifications.destroy_all
  end

  def destroy_reverse_friendship
    reverse = Friendship.find_by(user_id: friend_id, friend_id: user_id)
    reverse&.destroy
  end
end

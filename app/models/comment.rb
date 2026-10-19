# frozen_string_literal: true

class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
  belongs_to :parent_comment, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: "parent_comment_id", dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :user_id, presence: true
  validates :post_id, presence: true
  validates :content, presence: true, length: { minimum: 1, maximum: 1000 }
  validate :parent_comment_on_same_post

  scope :root_comments, -> { where(parent_comment_id: nil) }
  scope :recent, -> { order(created_at: :desc) }

  # After commit, so the job can find the comment
  after_create_commit :enqueue_notify_post_author
  after_destroy :cleanup_notifications

  private

  # A reply must belong to the same post as the comment it answers
  def parent_comment_on_same_post
    return unless parent_comment && parent_comment.post_id != post_id

    errors.add(:parent_comment, "must be on the same post")
  end

  # Enqueue a background job to notify the post author about this comment.
  # Keeping the model callback, but delegating side-effects to a job/service
  # improves testability and separates concerns.
  def enqueue_notify_post_author
    CommentNotificationJob.perform_later(id)
  end

  def cleanup_notifications
    notifications.destroy_all
  end
end

# frozen_string_literal: true

module Notifications
  class CommentNotifier
    def initialize(comment)
      @comment = comment
      @post = comment.post
      @recipient = @post.user
      @actor = comment.user
    end

    # Create a Notification record (Notification broadcasts it to the recipient).
    # This is extracted from the model to keep side-effects out of ActiveRecord callbacks.
    def call
      return if @actor == @recipient

      Notification.create!(
        user: @recipient,
        notification_type: "comment_created",
        notifiable: @comment
      )
    end
  end
end

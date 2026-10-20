# frozen_string_literal: true

module Follows
  # A user in a Followers / Following list
  class UserItemComponent < ViewComponent::Base
    attr_reader :user

    # following: whether the signed-in user follows this user (the list looks it up once)
    def initialize(user:, following:)
      @user = user
      @following = following
    end

    def following? = @following

    def username
      user.profile.username
    end

    def bio
      user.profile.bio.presence || "No bio yet"
    end
  end
end

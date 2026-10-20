# frozen_string_literal: true

class PagesController < ApplicationController
  before_action :authenticate_user!, only: [ :feed ]

  def home
    # Home page route - show authenticated user feed or landing page
    # Only published posts should appear on home feed
    if user_signed_in?
      @pagy, @posts = pagy(feed_posts, items: 20)
    end
  end

  # GET /home/feed?page=2 ("Load More Posts", turbo stream only)
  # Separate from home: Turbo follows redirects to home with the turbo stream Accept header
  # A page past the end appends nothing (the last page would add its posts a second time)
  def feed
    @pagy, @posts = pagy(feed_posts, items: 20, overflow: :empty_page)
  end

  private

  def feed_posts
    Post.published_only.recent.includes(:user, :post_images, :comments, :likes, :reactions)
  end
end

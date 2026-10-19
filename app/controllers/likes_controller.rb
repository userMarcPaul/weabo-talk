# frozen_string_literal: true

class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

# POST /posts/:post_id/likes
def create
  @like = @post.likes.create(user: current_user)

  respond_to do |format|
    format.turbo_stream
    format.html { redirect_to @post }
  end
end
# DELETE /posts/:post_id/likes/:id

def destroy
  @like = @post.likes.find_by(user: current_user)
  @like.destroy if @like

  respond_to do |format|
    format.turbo_stream
    format.html { redirect_to @post }
  end
end

  private

  def set_post
    @post = Post.visible_to(current_user).find(params[:post_id])
  end
end

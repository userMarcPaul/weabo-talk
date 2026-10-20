# frozen_string_literal: true

class FollowsController < ApplicationController
  before_action :authenticate_user!, except: [ :followers, :following ]
  before_action :set_user, except: [ :mine ]

  # GET /profiles/:username/follow: the Follow link for signed-out visitors. Signing in
  # (authenticate_user! remembers this URL) brings them back here, then to the profile.
  def show
    redirect_to profile_path(@user.profile.username)
  end

  # POST /profiles/:username/follow
  def create
    @follow = current_user.active_follows.build(followed: @user)

    saved = begin
      @follow.save
    rescue ActiveRecord::RecordNotUnique
      true # A request sent at the same moment (e.g. from another tab) already followed
    end

    respond_to do |format|
      if saved
        format.turbo_stream { render :update }
        format.html { redirect_to profile_path(@user.profile.username), notice: "You're following #{@user.profile.username}." }
      else
        format.turbo_stream { render :update, status: :unprocessable_entity }
        format.html { redirect_to profile_path(@user.profile.username), alert: @follow.errors.full_messages.to_sentence }
      end
    end
  end

  # DELETE /profiles/:username/follow
  def destroy
    current_user.active_follows.find_by(followed: @user)&.destroy

    respond_to do |format|
      format.turbo_stream { render :update }
      format.html { redirect_to profile_path(@user.profile.username), notice: "You unfollowed #{@user.profile.username}." }
    end
  end

  # GET /profiles/:username/followers
  def followers
    @list = :followers
    @pagy, @users = pagy(list_users(@user.followers), items: 20)
    render :index
  end

  # GET /profiles/:username/following
  def following
    @list = :following
    @pagy, @users = pagy(list_users(@user.following), items: 20)
    render :index
  end

  # GET /friendships, /friend-requests (the old friend pages)
  def mine
    redirect_to profile_following_path(current_user.profile.username)
  end

  private

  def set_user
    @user = Profile.find_by!(username: params[:username]).user
  end

  # Newest follows first. The follow buttons check this set instead of querying per user.
  def list_users(users)
    @following_ids = user_signed_in? ? current_user.active_follows.pluck(:followed_id).to_set : Set.new
    users.includes(profile: { avatar_attachment: :blob }).order("follows.created_at DESC")
  end
end

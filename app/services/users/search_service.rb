# frozen_string_literal: true

module Users
  # Encapsulates user search logic with proper keyword-based filtering
  class SearchService
    MIN_QUERY_LENGTH = 1  # Allow single character search
    MAX_RESULTS = 20

    def initialize(query)
      @query = query.to_s.strip
    end

    def search
      return [] if @query.blank? || @query.length < MIN_QUERY_LENGTH

      @results ||= sort_by_relevance(search_by_keyword).first(MAX_RESULTS)
    end

    def search_with_details
      profiles = search
      profiles.map do |profile|
        {
          id: profile.user_id,
          username: profile.username,
          bio: profile.bio.present? ? profile.bio : "No bio yet",
          avatar: profile.avatar.attached? ? generate_avatar_url(profile) : nil,
          friends_count: profile.user.friendships.where(status: "accepted").count
        }
      end
    end

    private

    # Search both username and bio for keyword matching (basic keyword search)
    def search_by_keyword
      # Escape % and _ so they match literally instead of acting as wildcards
      search_term = "%#{Profile.sanitize_sql_like(@query)}%"

      Profile
        .where("username ILIKE ? OR bio ILIKE ?", search_term, search_term)
        .includes(:user, avatar_attachment: :blob)
    end

    # Sort results by relevance
    def sort_by_relevance(profiles)
      # Sort in Ruby for simplicity
      # Sort: exact username match first → username contains → bio contains
      profiles.sort_by do |profile|
        rank = case profile.username.downcase
        when @query.downcase
          0  # Exact match (highest priority)
        when /^#{Regexp.escape(@query)}/i
          1  # Starts with query
        when /#{Regexp.escape(@query)}/i
          2  # Contains query in username
        else
          3  # Only bio contains query
        end

        # Username as tie-breaker keeps the order stable
        [ rank, profile.username ]
      end
    end

    # Relative path, so no host configuration is needed
    def generate_avatar_url(profile)
      Rails.application.routes.url_helpers.rails_blob_path(profile.avatar, only_path: true)
    end
  end
end

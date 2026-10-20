require "test_helper"

class Users::SearchServiceTest < ActiveSupport::TestCase
  setup do
    @naruto = create_user("naruto@example.com", bio: "Hokage")
    @naruto_fan = create_user("naruto_fan@example.com")
    @sasuke = create_user("sasuke@example.com", bio: "Rival of naruto")
  end

  # Basic Search
  test "should return no results for blank query" do
    assert_empty Users::SearchService.new("  ").search
  end

  test "should find profiles by username and bio" do
    results = Users::SearchService.new("naruto").search

    assert_equal 3, results.size
  end

  test "should rank exact match, then starts with, then bio match" do
    results = Users::SearchService.new("naruto").search

    assert_equal [ @naruto, @naruto_fan, @sasuke ].map(&:profile), results
  end

  test "should limit results" do
    results = Users::SearchService.new("a").search

    assert_operator results.size, :<=, Users::SearchService::MAX_RESULTS
  end

  # Wildcards
  test "should treat LIKE wildcards in query as literal characters" do
    assert_empty Users::SearchService.new("%").search
    assert_equal [ @naruto_fan.profile ], Users::SearchService.new("_").search
  end

  # Details (JSON)
  test "search_with_details should include each user's follower count" do
    Follow.create!(follower: @naruto_fan, followed: @naruto)

    details = Users::SearchService.new("naruto").search_with_details.index_by { |user| user[:username] }

    assert_equal 1, details["naruto"][:followers_count]
    assert_equal 0, details[@naruto_fan.profile.username][:followers_count]
  end

  test "search_with_details should include the smaller avatar's path when avatar is attached" do
    @naruto.profile.avatar.attach(io: StringIO.new(png_data), filename: "avatar.png", content_type: "image/png")

    details = Users::SearchService.new("naruto").search_with_details.find { |user| user[:username] == "naruto" }

    assert_match %r{\A/rails/active_storage/representations/}, details[:avatar]
  end

  test "search_with_details should return nil avatar and default bio when missing" do
    details = Users::SearchService.new("naruto_fan").search_with_details.first

    assert_nil details[:avatar]
    assert_equal "No bio yet", details[:bio]
  end

  private

  def create_user(email, bio: nil)
    user = User.create!(email: email, password: "password123", password_confirmation: "password123")
    user.profile.update!(bio: bio) if bio
    user
  end

  # Smallest valid PNG (1x1 transparent pixel)
  def png_data
    Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")
  end
end

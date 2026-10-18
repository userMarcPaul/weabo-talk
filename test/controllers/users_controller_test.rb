require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    User.create!(email: "naruto@example.com", password: "password123", password_confirmation: "password123")
  end

  # HTML Search
  test "should render search results page" do
    get search_users_path, params: { q: "naruto" }

    assert_response :success
    assert_includes response.body, "naruto"
  end

  test "should render search page without query" do
    get search_users_path

    assert_response :success
  end

  # JSON Search (real-time search box)
  test "should return JSON results" do
    post search_users_path, params: { q: "naruto" }, as: :json

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_equal 1, response.parsed_body["count"]
    assert_equal "naruto", response.parsed_body["users"].first["username"]
  end
end

require "test_helper"

# The Stimulus validators read the URL from a value attribute
# (data-<controller>-validation-url-value). Without it they post to the current page.
class LiveValidationWiringTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  VALIDATED_FORM = "form[data-controller=form-validation][data-form-validation-validation-url-value=?]".freeze

  test "devise forms should pass the validation url" do
    [ new_user_registration_path, new_user_session_path, new_user_confirmation_path, new_user_password_path ].each do |path|
      get path

      assert_select VALIDATED_FORM, validate_form_path, { minimum: 1 }, "no validated form on #{path}"
    end
  end

  test "comment and profile forms should pass the validation url" do
    user = User.create!(email: "writer@example.com", password: "password123", password_confirmation: "password123").tap(&:confirm)
    post_record = user.posts.create!(title: "Best anime", content: "Frieren")
    post_record.comments.create!(user: user, content: "First!")
    sign_in user

    get post_path(post_record)
    # The comment form and the reply form
    assert_select VALIDATED_FORM, validate_form_path, count: 2

    get edit_profile_path(user.profile.username)
    assert_select VALIDATED_FORM, validate_form_path, count: 1
  end
end

require "test_helper"

class ApplicationCable::ConnectionTest < ActionCable::Connection::TestCase
  # Stand-in for the Warden proxy Devise puts in the Rack env
  WardenProxy = Struct.new(:user)

  test "should connect signed in user" do
    user = User.create!(email: "cable@example.com", password: "password123", password_confirmation: "password123")

    connect env: { "warden" => WardenProxy.new(user) }

    assert_equal user, connection.current_user
  end

  test "should reject connection without signed in user" do
    assert_reject_connection { connect env: { "warden" => WardenProxy.new(nil) } }
  end
end

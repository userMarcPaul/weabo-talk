# Moves friendships to follows (plan decisions D2–D4):
# - accepted: both directions are stored, so each friend pair becomes a mutual follow
# - pending: the sender follows the receiver
# - blocked: dropped (not used by the app)
# Old friend-request notifications are deleted (their friendships are no longer used).
#
# The friendships table is kept as a backup until a later migration drops it. Its foreign
# keys to users are removed, so they can't block deleting an account in the meantime.
class MoveFriendshipsToFollows < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      INSERT INTO follows (follower_id, followed_id, created_at, updated_at)
      SELECT user_id, friend_id, created_at, updated_at
      FROM friendships
      WHERE status IN ('accepted', 'pending') AND user_id <> friend_id
      ON CONFLICT (follower_id, followed_id) DO NOTHING
    SQL

    execute "DELETE FROM notifications WHERE notification_type IN ('friend_request_sent', 'friend_request_accepted')"

    remove_foreign_key :friendships, :users, column: :user_id
    remove_foreign_key :friendships, :users, column: :friend_id
  end

  def down
    # Rows of users deleted since then would break the foreign keys
    execute "DELETE FROM friendships WHERE user_id NOT IN (SELECT id FROM users) OR friend_id NOT IN (SELECT id FROM users)"
    add_foreign_key :friendships, :users, column: :user_id
    add_foreign_key :friendships, :users, column: :friend_id
    execute "DELETE FROM follows"
  end
end

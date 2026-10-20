# One-way follows (replaces two-way friendships, see DOCUMENTS/FOLLOWERS_PROJECT_PLAN.md)
class CreateFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :follows do |t|
      # follower_id is covered by the unique index below
      t.references :follower, null: false, index: false, foreign_key: { to_table: :users }
      t.references :followed, null: false, foreign_key: { to_table: :users }
      t.timestamps

      t.index [ :follower_id, :followed_id ], unique: true
      t.check_constraint "follower_id <> followed_id", name: "follows_not_self"
    end
  end
end

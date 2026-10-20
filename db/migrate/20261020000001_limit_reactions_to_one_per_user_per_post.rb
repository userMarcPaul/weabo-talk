# A user has one reaction per post (like a like): picking another emoji switches it.
# Existing duplicates keep the user's most recent reaction; the others and their
# notifications are deleted.
class LimitReactionsToOnePerUserPerPost < ActiveRecord::Migration[8.1]
  def up
    duplicates = <<~SQL
      SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY user_id, post_id ORDER BY created_at DESC, id DESC) AS position
        FROM reactions
      ) ranked
      WHERE position > 1
    SQL

    execute "DELETE FROM notifications WHERE notifiable_type = 'Reaction' AND notifiable_id IN (#{duplicates})"
    execute "DELETE FROM reactions WHERE id IN (#{duplicates})"

    remove_index :reactions, [ :user_id, :post_id, :reaction_type ]
    add_index :reactions, [ :user_id, :post_id ], unique: true
  end

  def down
    remove_index :reactions, [ :user_id, :post_id ]
    add_index :reactions, [ :user_id, :post_id, :reaction_type ], unique: true
  end
end

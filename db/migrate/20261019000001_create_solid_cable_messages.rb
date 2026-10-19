# Action Cable messages for the Solid Cable adapter (production real-time notifications).
# Stored in the primary database, so no Redis or separate cable database is needed.
# Schema from solid_cable's install template (db/cable_schema.rb).
class CreateSolidCableMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :solid_cable_messages do |t|
      t.binary :channel, limit: 1024, null: false
      t.binary :payload, limit: 536_870_912, null: false
      t.datetime :created_at, null: false
      t.integer :channel_hash, limit: 8, null: false

      t.index :channel
      t.index :channel_hash
      t.index :created_at
    end
  end
end

# Active Storage keeps a row per generated image variant (the smaller WebP versions shown
# in pages, see ResizableImage). The project's original Active Storage migration didn't
# include this table. Same definition as Rails' active_storage:install migration.
class CreateActiveStorageVariantRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :active_storage_variant_records do |t|
      t.belongs_to :blob, null: false, index: false
      t.string :variation_digest, null: false

      t.index [ :blob_id, :variation_digest ], name: :index_active_storage_variant_records_uniqueness, unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  end
end

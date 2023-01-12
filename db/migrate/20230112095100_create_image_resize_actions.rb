class CreateImageResizeActions < ActiveRecord::Migration[5.2]
  def up
    create_table :image_resize_actions do |t|
      t.string :bucket, null: false
      t.string :path, null: false

      t.string :destination_path, null: false
      t.string :destination_size, null: false, default: :medium

      t.string :status, null: false

      t.timestamps

      t.index [:bucket, :path]
    end
  end

  def down
    remove_index :image_resize_actions, [:bucket, :path]

    drop_table :image_resize_actions
  end
end


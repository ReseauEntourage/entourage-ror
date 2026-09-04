class CreateAdminNotes < ActiveRecord::Migration[7.1]
  def change
    create_table :admin_notes do |t|
      t.string :notable_type, null: false
      t.integer :notable_id, null: false
      t.integer :author_id
      t.text :body, null: false

      t.timestamps
    end

    add_index :admin_notes, [:notable_type, :notable_id]
  end
end

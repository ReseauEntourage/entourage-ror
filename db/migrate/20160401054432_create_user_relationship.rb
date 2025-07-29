class CreateUserRelationship < ActiveRecord::Migration[4.2]
  def change
    create_table :user_relationships do |t|
      t.integer :source_user_id, null: false
      t.integer :target_user_id, null: false
      t.string  :relation_type,  null: false
    end

    add_index :user_relationships, [:source_user_id, :target_user_id, :relation_type], unique: true, name: 'unique_user_relationship'
  end
end

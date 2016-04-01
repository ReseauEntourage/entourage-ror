class CreateUserRelationship < ActiveRecord::Migration
  def change
    create_table :user_relationships do |t|
      t.integer :source_user_id, null: false
      t.integer :target_user_id, null: false
      t.string  :relation_type,  null: false
    end
  end
end

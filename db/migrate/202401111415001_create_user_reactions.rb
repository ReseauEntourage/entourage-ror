class CreateUserReactions < ActiveRecord::Migration[6.1]
  def up
    create_table :user_reactions do |t|
      t.integer :user_id, null: false
      t.integer :reaction_id, null: false
      t.integer :instance_id, null: false
      t.string :instance_type, null: false

      t.timestamps null: false

      # main usages
      # 1. find all user_reactions for a given instance
      # 2. find all user_reactions for a given instance and a given reaction_id
      t.index :reaction_id
      t.index [:instance_id, :instance_type]
    end
  end

  def down
    drop_table :user_reactions
  end
end


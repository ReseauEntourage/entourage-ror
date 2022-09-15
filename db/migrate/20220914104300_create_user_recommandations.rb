class CreateUserRecommandations < ActiveRecord::Migration[5.2]
  def up
    create_table :user_recommandations do |t|
      t.integer :user_id, null: false
      t.integer :recommandation_id, null: false

      t.datetime :completed_at
      t.datetime :congrats_at
      t.datetime :skipped_at

      t.string :name, null: false
      t.string :image_url
      t.string :action, null: false
      t.string :instance_type, null: false
      t.integer :instance_id
      t.string :instance_url

      t.timestamps null: false

      t.index :user_id
      t.index :recommandation_id
    end
  end

  def down
    remove_index :user_recommandations, :user_id
    remove_index :user_recommandations, :recommandation_id

    drop_table :user_recommandations
  end
end


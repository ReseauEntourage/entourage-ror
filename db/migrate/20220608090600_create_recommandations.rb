class CreateRecommandations < ActiveRecord::Migration[5.2]
  def up
    create_table :recommandations do |t|
      t.string :name, limit: 256
      t.string :image_url
      t.string :profile # offer_help, ask_for_help, organization

      # link
      t.string :instance, null: false
      t.string :action, null: false, default: :show
      t.string :url

      t.timestamps null: false

      t.index :name
      t.index :profile
      t.index :instance
      t.index :action
    end
  end

  def down
    remove_index :recommandations, :name
    remove_index :recommandations, :profile
    remove_index :recommandations, :instance
    remove_index :recommandations, :action

    drop_table :recommandations
  end
end

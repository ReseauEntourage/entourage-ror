class CreateReactions < ActiveRecord::Migration[6.1]
  def up
    create_table :reactions do |t|
      t.string :name
      t.string :key
      t.string :image_url
    end
  end

  def down
    drop_table :reactions
  end
end


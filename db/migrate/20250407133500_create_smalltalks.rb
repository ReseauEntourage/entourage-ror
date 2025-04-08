class CreateSmalltalks < ActiveRecord::Migration[6.1]
  def change
    create_table :smalltalks do |t|
      t.string :uuid_v2, limit: 12

      # denorms
      t.integer :number_of_people
      t.integer :number_of_root_chat_messages

      t.index :uuid_v2, unique: true
    end
  end
end

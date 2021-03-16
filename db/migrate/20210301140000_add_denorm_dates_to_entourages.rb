class AddDenormDatesToEntourages < ActiveRecord::Migration
  def up
    create_table :entourage_denorms do |t|
      t.integer :entourage_id, null: false
      t.datetime :max_join_request_requested_at
      t.datetime :max_chat_message_created_at
      t.timestamps null: false
      t.index :entourage_id
    end
  end

  def down
    drop_table :entourage_denorms
  end
end


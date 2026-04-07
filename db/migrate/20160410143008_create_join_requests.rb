class CreateJoinRequests < ActiveRecord::Migration[4.2]
  def change
    create_table :join_requests do |t|
      t.integer   :user_id,             null: false
      t.integer   :joinable_id,         null: false
      t.string    :joinable_type,       null: false
      t.string    :status,              null: false, default: 'pending'
      t.text      :message,             null: true
      t.datetime  :last_message_read,   null: true

      t.timestamps null: false
    end
    add_index :join_requests, [:user_id, :joinable_id], unique: true
    add_index :join_requests, [:user_id, :joinable_id, :joinable_type, :status], name: 'index_user_joinable_on_join_requests'
  end
end

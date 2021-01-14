class AddLastMessageReadToEntourageUser < ActiveRecord::Migration[4.2]
  def change
    add_column  :entourages_users, :last_message_read, :datetime, null: true
  end
end

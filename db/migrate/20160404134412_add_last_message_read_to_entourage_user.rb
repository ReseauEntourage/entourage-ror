class AddLastMessageReadToEntourageUser < ActiveRecord::Migration
  def change
    add_column  :entourages_users, :last_message_read, :datetime, null: true
  end
end

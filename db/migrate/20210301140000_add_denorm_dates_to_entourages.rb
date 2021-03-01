class AddDenormDatesToEntourages < ActiveRecord::Migration
  def change
    add_column :entourages, :max_chat_message_created_at, :datetime
    add_column :entourages, :max_join_request_requested_at, :datetime
  end
end


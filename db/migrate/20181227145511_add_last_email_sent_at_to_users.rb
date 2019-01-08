class AddLastEmailSentAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_email_sent_at, :datetime
  end
end

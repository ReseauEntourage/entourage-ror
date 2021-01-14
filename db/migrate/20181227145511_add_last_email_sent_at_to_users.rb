class AddLastEmailSentAtToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :last_email_sent_at, :datetime
  end
end

class AddEmailSentToTours < ActiveRecord::Migration[4.2]
  def change
    add_column :tours, :email_sent, :boolean, default: false
  end
end

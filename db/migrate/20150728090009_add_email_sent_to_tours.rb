class AddEmailSentToTours < ActiveRecord::Migration
  def change
    add_column :tours, :email_sent, :boolean, default: false
  end
end

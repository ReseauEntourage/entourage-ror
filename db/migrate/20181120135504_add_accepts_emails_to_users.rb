class AddAcceptsEmailsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :accepts_emails, :boolean, default: true, null: false
  end
end

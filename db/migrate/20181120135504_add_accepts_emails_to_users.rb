class AddAcceptsEmailsToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :accepts_emails, :boolean, default: true, null: false
  end
end

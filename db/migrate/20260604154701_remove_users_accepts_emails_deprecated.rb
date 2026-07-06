class RemoveUsersAcceptsEmailsDeprecated < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :accepts_emails_deprecated
  end
end


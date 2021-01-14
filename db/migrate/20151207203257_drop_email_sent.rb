class DropEmailSent < ActiveRecord::Migration[4.2]
  def up
    remove_column :tours, :email_sent
  end

  def down
    add_column :tours, :email_sent, :boolean
  end
end

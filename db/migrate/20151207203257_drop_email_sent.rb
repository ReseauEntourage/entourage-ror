class DropEmailSent < ActiveRecord::Migration
  def up
    remove_column :tours, :email_sent
  end

  def down
    add_column :tours, :email_sent, :boolean
  end
end

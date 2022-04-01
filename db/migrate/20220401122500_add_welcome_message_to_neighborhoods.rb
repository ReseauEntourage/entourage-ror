class AddWelcomeMessageToNeighborhoods < ActiveRecord::Migration[5.2]
  def up
    add_column :neighborhoods, :welcome_message, :string
  end

  def down
    remove_column :neighborhoods, :welcome_message
  end
end

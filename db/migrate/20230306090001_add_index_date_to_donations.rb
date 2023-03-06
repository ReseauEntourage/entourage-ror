class AddIndexDateToDonations < ActiveRecord::Migration[5.2]
  def up
    add_index :donations, :date
  end

  def down
    remove_index :donations, :date
  end
end

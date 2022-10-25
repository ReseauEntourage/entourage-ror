class AddStatusChangedAtToEntourages < ActiveRecord::Migration[5.2]
  def up
    add_column :entourages, :status_changed_at, :datetime
  end

  def down
    remove_column :entourages, :status_changed_at
  end
end


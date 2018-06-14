class AddGroupTypeToEntourages < ActiveRecord::Migration
  def up
    add_column :entourages, :group_type, :string, limit: 14
    Entourage.where(community: :entourage).update_all(group_type: :action)
    Entourage.where(community: :pfp      ).update_all(group_type: :private_circle)
    change_column_null :entourages, :group_type, false
  end

  def down
    remove_column :entourages, :group_type
  end
end

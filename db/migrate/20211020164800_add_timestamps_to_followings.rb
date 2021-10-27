class AddTimestampsToFollowings < ActiveRecord::Migration[5.2]
  def up
    add_column :followings, :created_at, :datetime
    add_column :followings, :updated_at, :datetime
  end

  def down
    remove_column :followings, :created_at
    remove_column :followings, :updated_at
  end
end

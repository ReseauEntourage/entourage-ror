class RenameInstanceTypeToInstanceOnUserRecommandations < ActiveRecord::Migration[5.2]
  def up
    rename_column :user_recommandations, :instance_type, :instance
  end

  def down
    rename_column :user_recommandations, :instance, :instance_type
  end
end


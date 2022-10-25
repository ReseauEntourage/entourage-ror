class RemoveProfileFromRecommandations < ActiveRecord::Migration[5.2]
  def up
    remove_index :recommandations, :profile
    remove_column :recommandations, :profile
  end

  def down
    add_column :recommandations, :profile, :string
    add_index :recommandations, :profile
  end
end

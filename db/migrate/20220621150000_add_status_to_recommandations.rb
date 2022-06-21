class AddStatusToRecommandations < ActiveRecord::Migration[5.2]
  def up
    add_column :recommandations, :status, :string, null: false, default: :active
  end

  def down
    remove_column :recommandations, :status
  end
end

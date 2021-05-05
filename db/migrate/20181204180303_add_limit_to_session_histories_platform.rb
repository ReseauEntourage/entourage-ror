class AddLimitToSessionHistoriesPlatform < ActiveRecord::Migration[4.2]
  def up
    change_column :session_histories, :platform, :string, null: false, limit: 7
  end

  def down
    change_column :session_histories, :platform, :string, null: false
  end
end

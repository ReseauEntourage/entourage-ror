class AddFragmentToUserRecommandations < ActiveRecord::Migration[5.2]
  def up
    add_column :user_recommandations, :fragment, :integer
  end

  def down
    remove_column :user_recommandations, :fragment
  end
end

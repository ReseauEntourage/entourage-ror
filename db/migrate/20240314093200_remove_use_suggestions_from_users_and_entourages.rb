class RemoveUseSuggestionsFromUsersAndEntourages < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :use_suggestions
    remove_column :entourages, :use_suggestions
  end
end

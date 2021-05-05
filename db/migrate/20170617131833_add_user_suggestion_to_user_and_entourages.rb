class AddUserSuggestionToUserAndEntourages < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :use_suggestions, :boolean, null: false, default: false
    add_column :entourages, :use_suggestions, :boolean, null: false, default: false
  end
end

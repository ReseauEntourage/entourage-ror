class AddUniqueIndexToUserScoringsOnUserIdAndDate < ActiveRecord::Migration[6.1]
  def change
    add_index :user_scorings, [:user_id, :date], unique: true, name: 'index_user_scorings_on_user_id_and_date'
  end
end

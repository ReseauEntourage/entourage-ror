class AddCommunityToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :community, :string, limit: 9
  end
end

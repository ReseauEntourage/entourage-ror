class AddCommunityToUsers < ActiveRecord::Migration
  def change
    add_column :users, :community, :string, limit: 9
  end
end

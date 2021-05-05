class AddCommunityToEntourages < ActiveRecord::Migration[4.2]
  def change
    add_column :entourages, :community, :string, limit: 9
  end
end

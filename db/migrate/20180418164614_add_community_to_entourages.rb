class AddCommunityToEntourages < ActiveRecord::Migration
  def change
    add_column :entourages, :community, :string, limit: 9
  end
end

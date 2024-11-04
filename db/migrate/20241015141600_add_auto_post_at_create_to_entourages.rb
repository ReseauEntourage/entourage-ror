class AddAutoPostAtCreateToEntourages < ActiveRecord::Migration[6.1]
  def change
    add_column :entourages, :auto_post_at_create, :boolean, default: false
  end
end

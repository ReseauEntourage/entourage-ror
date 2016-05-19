class AddDescriptionToEntourage < ActiveRecord::Migration
  def change
    add_column :entourages, :description, :string, null: true
  end
end

class AddDescriptionToEntourage < ActiveRecord::Migration[4.2]
  def change
    add_column :entourages, :description, :string, null: true
  end
end

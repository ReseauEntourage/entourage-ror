class AddValidatedToPoi < ActiveRecord::Migration[4.2]
  def change
    add_column :pois, :validated, :boolean, null: false, default: false
  end
end

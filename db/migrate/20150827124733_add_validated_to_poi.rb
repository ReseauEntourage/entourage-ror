class AddValidatedToPoi < ActiveRecord::Migration
  def change
    add_column :pois, :validated, :boolean, null: false, default: false
  end
end

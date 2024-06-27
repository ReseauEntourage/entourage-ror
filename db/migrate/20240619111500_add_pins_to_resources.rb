class AddPinsToResources < ActiveRecord::Migration[6.1]
  def change
    add_column :resources, :pin_offer_help, :boolean, default: false
    add_column :resources, :pin_ask_for_help, :boolean, default: false
  end
end

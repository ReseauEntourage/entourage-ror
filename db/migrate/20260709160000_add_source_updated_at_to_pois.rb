class AddSourceUpdatedAtToPois < ActiveRecord::Migration[7.1]
  def change
    add_column :pois, :source_updated_at, :string
  end
end

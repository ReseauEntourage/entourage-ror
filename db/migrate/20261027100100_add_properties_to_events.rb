class AddPropertiesToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :properties, :jsonb
  end
end

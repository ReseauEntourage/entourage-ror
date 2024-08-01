class AddNationalToNeighborhoods < ActiveRecord::Migration[6.1]
  def change
    add_column :neighborhoods, :national, :boolean, default: false

    # low cardinality of national = true
    # high usage of filter national = true
    add_index :neighborhoods, :national
  end
end

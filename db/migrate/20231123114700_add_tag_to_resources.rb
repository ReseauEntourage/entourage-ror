class AddTagToResources < ActiveRecord::Migration[6.1]
  def change
    add_column :resources, :tag, :string, default: nil
    add_index :resources, :tag
  end
end

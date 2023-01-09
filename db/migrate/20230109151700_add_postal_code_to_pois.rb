class AddPostalCodeToPois < ActiveRecord::Migration[5.2]
  def up
    add_column :pois, :postal_code, :string

    add_index :pois, :postal_code
  end

  def down
    remove_index :pois, :postal_code
    
    remove_column :pois, :postal_code
  end
end


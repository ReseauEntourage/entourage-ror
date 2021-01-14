class CreateOrganizations < ActiveRecord::Migration[4.2]
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :description
      t.string :phone
      t.string :address

      t.timestamps null: false
    end
  end
end

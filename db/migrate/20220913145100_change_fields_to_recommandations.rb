class ChangeFieldsToRecommandations < ActiveRecord::Migration[5.2]
  def up
    add_column :recommandations, :position, :integer
    add_column :recommandations, :fragment, :integer
    add_column :recommandations, :description, :string, null: true
    add_column :recommandations, :argument_value, :string, null: true, default: nil
    add_column :recommandations, :conditional_display, :boolean, null: false, default: false

    remove_index :recommandations, :areas
    remove_column :recommandations, :areas

    remove_column :recommandations, :url

    add_index :recommandations, [:status, :position, :fragment], unique: true
  end

  def down
    remove_index :recommandations, [:status, :position, :fragment]

    remove_column :recommandations, :position
    remove_column :recommandations, :fragment
    remove_column :recommandations, :description
    remove_column :recommandations, :argument_value
    remove_column :recommandations, :conditional_display

    add_column :recommandations, :areas, :jsonb, default: [], null: false
    add_index  :recommandations, :areas, using: :gin

    add_column :recommandations, :url, :string
  end
end

class ChangeFieldsToRecommandations < ActiveRecord::Migration[5.2]
  def up
    add_column :recommandations, :position_offer_help, :integer
    add_column :recommandations, :position_ask_for_help, :integer
    add_column :recommandations, :fragment, :integer, default: 0, null: true
    add_column :recommandations, :description, :string, null: true
    add_column :recommandations, :argument_value, :string, null: true, default: nil

    remove_index :recommandations, :areas
    remove_column :recommandations, :areas

    remove_column :recommandations, :url

    add_index :recommandations, [:status, :position_offer_help, :fragment], where: "status = 'active' and position_offer_help is not null", name: "index_recommandations_on_status_and_position_offer_help", unique: true
    add_index :recommandations, [:status, :position_ask_for_help, :fragment], where: "status = 'active' and position_ask_for_help is not null", name: "index_recommandations_on_status_and_position_ask_for_help", unique: true
  end

  def down
    remove_index :recommandations, [:status, :position_offer_help, :fragment]
    remove_index :recommandations, [:status, :position_ask_for_help, :fragment]

    remove_column :recommandations, :position_offer_help
    remove_column :recommandations, :position_ask_for_help
    remove_column :recommandations, :fragment
    remove_column :recommandations, :description
    remove_column :recommandations, :argument_value

    add_column :recommandations, :areas, :jsonb, default: [], null: false
    add_index  :recommandations, :areas, using: :gin

    add_column :recommandations, :url, :string
  end
end

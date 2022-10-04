class RemoveUnicityOnRecommandations < ActiveRecord::Migration[5.2]
  def up
    remove_index :recommandations, [:status, :position_offer_help, :fragment]
    remove_index :recommandations, [:status, :position_ask_for_help, :fragment]

    add_index :recommandations, [:status, :position_offer_help, :fragment], where: "status = 'active' and position_offer_help is not null", name: "index_recommandations_on_status_and_position_offer_for_help"
    add_index :recommandations, [:status, :position_ask_for_help, :fragment], where: "status = 'active' and position_ask_for_help is not null", name: "index_recommandations_on_status_and_position_ask_for_help"
  end

  def down
    remove_index :recommandations, [:status, :position_offer_help, :fragment]
    remove_index :recommandations, [:status, :position_ask_for_help, :fragment]

    add_index :recommandations, [:status, :position_offer_help, :fragment], where: "status = 'active' and position_offer_help is not null", name: "index_recommandations_on_status_and_position_offer_for_help", unique: true
    add_index :recommandations, [:status, :position_ask_for_help, :fragment], where: "status = 'active' and position_ask_for_help is not null", name: "index_recommandations_on_status_and_position_ask_for_help", unique: true
  end
end


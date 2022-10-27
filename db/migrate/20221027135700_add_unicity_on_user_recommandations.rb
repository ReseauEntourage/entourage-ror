class AddUnicityOnUserRecommandations < ActiveRecord::Migration[5.2]
  def up
    add_index :user_recommandations, [:user_id, :recommandation_id], where: "completed_at is null and skipped_at is null", name: "index_user_recommandations_on_user_id_and_recommandation_id", unique: true
  end

  def down
    remove_index :user_recommandations, [:user_id, :recommandation_id]
  end
end

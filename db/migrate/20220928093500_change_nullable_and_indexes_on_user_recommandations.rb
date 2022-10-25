class ChangeNullableAndIndexesOnUserRecommandations < ActiveRecord::Migration[5.2]
  def up
    change_column_null :user_recommandations, :recommandation_id, true
    change_column_null :user_recommandations, :name, true

    remove_index :user_recommandations, :recommandation_id
    add_index :user_recommandations, :instance_type
    add_index :user_recommandations, [:completed_at, :skipped_at]
  end

  def down
    change_column_null :user_recommandations, :recommandation_id, false
    change_column_null :user_recommandations, :name, false

    add_index :user_recommandations, :recommandation_id
    remove_index :user_recommandations, :instance_type
    remove_index :user_recommandations, [:completed_at, :skipped_at]
  end
end


class CreateDenormDailyEngagementsWithType < ActiveRecord::Migration[7.1]
  def change
    return if table_exists?(:denorm_daily_engagements_with_type)

    create_table :denorm_daily_engagements_with_type do |t|
      t.date :date, null: false
      t.integer :user_id, null: false
      t.string :postal_code
      t.string :engagement_type, default: '--', null: false
    end

    add_index :denorm_daily_engagements_with_type,
              [:date, :user_id, :postal_code, :engagement_type],
              unique: true,
              name: "index_denorm_daily_engagements_on_all_fields"

    add_index :denorm_daily_engagements_with_type,
              [:date, :user_id],
              name: "index_denorm_daily_engagements_on_date_user"
  end
end

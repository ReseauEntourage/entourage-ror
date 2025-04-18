class CreateDenormDailyEncounters < ActiveRecord::Migration[5.2]
  def up
    create_table :denorm_daily_encounters do |t|
      t.date :creation_date, null: false
      t.string :encounter_type
      t.integer :user1_id, null: false
      t.integer :user2_id, null: false

      t.index [:creation_date, :encounter_type, :user1_id, :user2_id], unique: true, name: 'unicity_denorm_daily_encounters_on_date_encounter_type_users'
    end
  end

  def down
    remove_index :denorm_daily_encounters, [:creation_date, :encounter_type, :user1_id, :user2_id]

    drop_table :denorm_daily_encounters
  end
end

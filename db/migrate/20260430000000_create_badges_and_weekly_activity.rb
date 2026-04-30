class CreateBadgesAndWeeklyActivity < ActiveRecord::Migration[7.1]
  def up
    create_table :user_badges do |t|
      t.integer :user_id, null: false
      t.string :badge_tag, null: false
      t.boolean :active, default: true, null: false
      t.datetime :awarded_at, null: false
      t.jsonb :metadata, default: {}, null: false
      t.timestamps
    end
    add_index :user_badges, [:user_id, :badge_tag], unique: true

    create_table :weekly_activities do |t|
      t.integer :user_id, null: false
      t.string :week_iso, null: false
      t.boolean :has_group_action, default: false, null: false
      t.timestamps
    end
    add_index :weekly_activities, [:user_id, :week_iso], unique: true

    # Update event_name enum
    execute <<-SQL
      ALTER TYPE event_name ADD VALUE 'badge.bienvenue.awarded';
      ALTER TYPE event_name ADD VALUE 'badge.premier_contact.awarded';
      ALTER TYPE event_name ADD VALUE 'badge.moteur_rencontres.awarded';
      ALTER TYPE event_name ADD VALUE 'badge.moteur_rencontres.deactivated';
      ALTER TYPE event_name ADD VALUE 'badge.fidele_papotages.awarded';
      ALTER TYPE event_name ADD VALUE 'badge.fidele_papotages.deactivated';
      ALTER TYPE event_name ADD VALUE 'badge.voix_presente.awarded';
      ALTER TYPE event_name ADD VALUE 'badge.voix_presente.deactivated';
    SQL
  end

  def down
    drop_table :user_badges
    drop_table :weekly_activities
  end
end

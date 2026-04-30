class CreateBadgesAndWeeklyActivity < ActiveRecord::Migration[7.1]
  def up
    unless table_exists?(:user_badges)
      create_table :user_badges do |t|
        t.integer :user_id, null: false
        t.string :badge_tag, null: false
        t.boolean :active, default: true, null: false
        t.datetime :awarded_at, null: false
        t.jsonb :metadata, default: {}, null: false
        t.timestamps
      end
      add_index :user_badges, [:user_id, :badge_tag], unique: true
    end

    unless table_exists?(:weekly_activities)
      create_table :weekly_activities do |t|
        t.integer :user_id, null: false
        t.string :week_iso, null: false
        t.boolean :has_group_action, default: false, null: false
        t.timestamps
      end
      add_index :weekly_activities, [:user_id, :week_iso], unique: true
    end

    # Update event_name enum by recreating it (robust against transaction blocks)
    # We use a robust pattern that works even within transactions
    execute <<-SQL
      DO $$
      BEGIN
        IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'event_name_old') THEN
          DROP TYPE event_name_old CASCADE;
        END IF;
      END
      $$;

      ALTER TYPE event_name RENAME TO event_name_old;

      CREATE TYPE event_name AS ENUM (
        'onboarding.profile.first_name.entered',
        'onboarding.chat_messages.welcome.sent',
        'onboarding.chat_messages.welcome.skipped',
        'onboarding.profile.postal_code.entered',
        'onboarding.push_notifications.welcome.sent',
        'onboarding.chat_messages.ethical_charter.sent',
        'onboarding.chat_messages.incomplete_profile.sent',
        'onboarding.resource.welcome_watched',
        'onboarding.outing.webinar_or_first_steps',
        'onboarding.outing.papotages',
        'badge.bienvenue.awarded',
        'badge.premier_contact.awarded',
        'badge.moteur_rencontres.awarded',
        'badge.moteur_rencontres.deactivated',
        'badge.fidele_papotages.awarded',
        'badge.fidele_papotages.deactivated',
        'badge.voix_presente.awarded',
        'badge.voix_presente.deactivated'
      );

      ALTER TABLE events ALTER COLUMN name TYPE event_name USING name::text::event_name;

      DROP TYPE event_name_old;
    SQL

    Event.reset_event_names_cache! if defined?(Event)
  end

  def down
    drop_table :user_badges if table_exists?(:user_badges)
    drop_table :weekly_activities if table_exists?(:weekly_activities)
  end
end

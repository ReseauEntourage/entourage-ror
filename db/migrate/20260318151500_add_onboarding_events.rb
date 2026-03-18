class AddOnboardingEvents < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    execute <<-SQL
      alter type event_name add value 'onboarding.resource.welcome_watched';
      alter type event_name add value 'onboarding.outing.webinar_or_first_steps';
      alter type event_name add value 'onboarding.outing.papotages'
    SQL

    Event.reset_event_names_cache!
  end

  def down
    Event.where(name: 'onboarding.resource.welcome_watched').delete_all
    Event.where(name: 'onboarding.outing.webinar_or_first_steps').delete_all
    Event.where(name: 'onboarding.outing.papotages').delete_all

    # https://blog.yo1.dog/updating-enum-values-in-postgresql-the-safe-and-easy-way/
    execute <<-SQL
      -- rename the existing type
      alter type event_name rename to event_name_old;

      -- create a new type without the removed value
      create type event_name as enum (
         'onboarding.profile.first_name.entered',
         'onboarding.chat_messages.welcome.sent',
         'onboarding.chat_messages.welcome.skipped',
         'onboarding.profile.postal_code.entered',
         'onboarding.profile.goal.entered',
         'onboarding.push_notifications.welcome.sent',
         'onboarding.chat_messages.ethical_charter.sent',
         'onboarding.chat_messages.incomplete_profile.sent'
      );

      -- update the columns to use the new type, via an intermediate conversion to text
      alter table events alter column name type event_name using name::text::event_name;

      -- remove the old type
      drop type event_name_old;
    SQL
  end
end

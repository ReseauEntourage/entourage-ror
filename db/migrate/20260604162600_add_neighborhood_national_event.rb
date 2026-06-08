class AddNeighborhoodNationalEvent < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    execute "alter type event_name add value IF NOT EXISTS 'onboarding.neighborhood.national'"

    Event.reset_event_names_cache!
  end

  def down
    # PostgreSQL does not support removing enum values without recreating the type
  end
end

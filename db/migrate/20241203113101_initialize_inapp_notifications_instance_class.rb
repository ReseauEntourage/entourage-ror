class InitializeInappNotificationsInstanceClass < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL.squish
      UPDATE inapp_notifications
      SET instance_baseclass = case
        when instance = 'outing' then 'Entourage'
        when instance = 'contribution' then 'Entourage'
        when instance = 'solicitation' then 'Entourage'
        when instance = 'neighborhood_post' then 'ChatMessage'
        when instance = 'outing_post' then 'ChatMessage'
        else initcap(instance)
      end
    SQL
  end
end

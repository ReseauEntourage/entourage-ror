class AddProviderToSmsDeliveries < ActiveRecord::Migration
  def up
    execute <<-SQL
      create type sms_delivery_provider as enum (
        'AWS',
        'Nexmo',
        'Slack',
        'logs'
      )
    SQL

    add_column :sms_deliveries, :provider, :sms_delivery_provider
  end

  def down
    remove_column :sms_deliveries, :provider
    execute %(drop type sms_delivery_provider)
  end
end

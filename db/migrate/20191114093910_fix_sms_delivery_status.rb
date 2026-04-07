class FixSmsDeliveryStatus < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      create type sms_delivery_status as enum (
        'Ok',
        'Provider Error',
        'Sending Error'
      )
    SQL

    change_column :sms_deliveries, :status, :sms_delivery_status, using: "'Ok'"
  end

  def down
    change_column :sms_deliveries, :status, :integer, using: '0'
    execute %(drop type sms_delivery_status)
  end
end

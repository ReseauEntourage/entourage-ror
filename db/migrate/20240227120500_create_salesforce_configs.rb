class CreateSalesforceConfigs < ActiveRecord::Migration[6.1]
  def change
    create_table :salesforce_configs do |t|
      t.string :klass, null: false
      t.string :developer_name
      t.string :salesforce_id

      t.timestamps null: false

      t.index :salesforce_id
    end
  end
end

class RenameDeveloperNameInSalesforceConfigs < ActiveRecord::Migration[7.1]
  def change
    rename_column :salesforce_configs, :developer_name, :name
  end
end


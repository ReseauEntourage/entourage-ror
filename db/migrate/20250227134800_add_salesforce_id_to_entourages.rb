class AddSalesforceIdToEntourages < ActiveRecord::Migration[6.1]
  def change
    add_column :entourages, :salesforce_id, :string
  end
end

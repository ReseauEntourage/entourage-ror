require "#{Rails.root}/lib/tasks/populate.rb"

class PopulateSalesforceConfigs < ActiveRecord::Migration[6.1]
  def up
    return if EnvironmentHelper.test?

    # Populate.set_salesforce_configs
  end

  def down
    Populate.delete_salesforce_configs
  end
end


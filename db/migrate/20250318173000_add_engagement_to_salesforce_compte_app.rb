class AddEngagementToSalesforceCompteApp < ActiveRecord::Migration[6.1]
  def up
    unless Rails.env.test?
      SalesforceServices::TableInterface.create_field(
        "Compte_App__c",
        "LastEngagementDate__c",
        "Last Engagement Date",
        "Date"
      )

      SalesforceServices::TableInterface.create_field(
        "Compte_App__c",
        "IsEngaged__c",
        "Is Engaged",
        "Checkbox",
        default_value: "false"
      )
    end
  end

  def down
    unless Rails.env.test?
      SalesforceServices::TableInterface.delete_field("Compte_App__c", "LastEngagementDate__c")
      SalesforceServices::TableInterface.delete_field("Compte_App__c", "IsEngaged__c")
    end
  end
end

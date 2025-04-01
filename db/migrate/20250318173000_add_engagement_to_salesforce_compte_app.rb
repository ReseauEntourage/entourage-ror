class AddEngagementToSalesforceCompteApp < ActiveRecord::Migration[6.1]
  def up
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

  def down
    SalesforceServices::TableInterface.delete_field("Compte_App__c", "LastEngagementDate__c")
    SalesforceServices::TableInterface.delete_field("Compte_App__c", "IsEngaged__c")
  end
end

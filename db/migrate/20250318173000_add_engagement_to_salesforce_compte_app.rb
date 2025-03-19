class AddEngagementToSalesforceCompteApp < ActiveRecord::Migration[6.1]
  def up
    # raise unless SalesforceServices::TableInterface.create_field(
    #   "Compte_App__c",
    #   "LastEngagementDate__c",
    #   "Last Engagement Date",
    #   "Date"
    # )

    # raise unless SalesforceServices::TableInterface.create_field(
    #   "Compte_App__c",
    #   "IsEngaged__c",
    #   "Is Engaged",
    #   "Checkbox",
    #   default_value: "false"
    # )
  end

  def down
    # raise unless SalesforceServices::TableInterface.delete_field("Compte_App__c", "LastEngagementDate__c")
    # raise unless SalesforceServices::TableInterface.delete_field("Compte_App__c", "IsEngaged__c")
  end
end

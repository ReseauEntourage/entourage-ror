class AddJoinRequestIdToSalesforceCampaignMember < ActiveRecord::Migration[6.1]
  def up
    unless Rails.env.test?
      SalesforceServices::TableInterface.create_field(
        "CampaignMember",
        "JoinRequestId__c",
        "JoinRequestId",
        "Number",
        default_value: nil
      )
    end
  end

  def down
    unless Rails.env.test?
      SalesforceServices::TableInterface.delete_field("CampaignMember", "JoinRequestId__c")
    end
  end
end

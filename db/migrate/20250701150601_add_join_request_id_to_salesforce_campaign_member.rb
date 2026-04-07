class AddJoinRequestIdToSalesforceCampaignMember < ActiveRecord::Migration[6.1]
  def up
    unless Rails.env.test?
      # SalesforceServices::TableInterface.create_field(
      #   "CampaignMember",
      #   "JoinRequestId",
      #   "JoinRequestId",
      #   "Number"
      # )
    end
  end

  def down
    unless Rails.env.test?
      SalesforceServices::TableInterface.delete_field("CampaignMember", "JoinRequestId")
    end
  end
end

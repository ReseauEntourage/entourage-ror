class CreateEmailCampaigns < ActiveRecord::Migration
  def up
    create_table :email_campaigns do |t|
      t.string :name, null: false, limit: 40
    end

    add_column :email_deliveries, :email_campaign_id, :integer

    EmailDelivery.reset_column_information

    EmailDelivery.distinct.pluck(:campaign).each do |name|
      campaign = EmailCampaign.find_or_create_by!(name: name)
      EmailDelivery.where(campaign: name).update_all(email_campaign_id: campaign.id)
    end

    change_column_null :email_deliveries, :email_campaign_id, false
    add_index :email_deliveries, [:user_id, :email_campaign_id]

    remove_column :email_deliveries, :campaign
  end

  def down
    add_column :email_deliveries, :campaign, :string

    EmailDelivery.reset_column_information

    EmailDelivery.distinct.pluck(:email_campaign_id).each do |id|
      campaign = EmailCampaign.find_by!(id: id)
      EmailDelivery.where(email_campaign_id: id).update_all(campaign: campaign.name)
    end

    change_column_null :email_deliveries, :campaign, false
    add_index :email_deliveries, [:user_id, :campaign]

    remove_column :email_deliveries, :email_campaign_id

    drop_table :email_campaigns
  end
end

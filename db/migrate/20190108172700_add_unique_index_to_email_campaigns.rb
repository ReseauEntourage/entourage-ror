class AddUniqueIndexToEmailCampaigns < ActiveRecord::Migration
  def change
    add_index :email_campaigns, :name, unique: true
  end
end

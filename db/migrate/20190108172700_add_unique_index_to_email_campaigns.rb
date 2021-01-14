class AddUniqueIndexToEmailCampaigns < ActiveRecord::Migration[4.2]
  def change
    add_index :email_campaigns, :name, unique: true
  end
end

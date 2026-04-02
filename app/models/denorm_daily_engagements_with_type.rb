class DenormDailyEngagementsWithType < ApplicationRecord
  self.table_name = "denorm_daily_engagements_with_type"

  belongs_to :user

  after_create :sync_salesforce

  def sync_salesforce
    user.sync_salesforce(true)
  end
end

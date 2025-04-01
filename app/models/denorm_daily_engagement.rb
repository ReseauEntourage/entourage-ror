class DenormDailyEngagement < ApplicationRecord
  belongs_to :user

  after_create :sync_salesforce

  def sync_salesforce
    user.sync_salesforce(true)
  end
end

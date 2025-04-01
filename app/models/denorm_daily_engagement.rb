class DenormDailyEngagement < ApplicationRecord
  belongs_to :user

  delegate :sync_salesforce, to: :user

  after_create :sync_salesforce
end

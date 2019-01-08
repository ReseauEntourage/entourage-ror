class EmailDelivery < ActiveRecord::Base
  belongs_to :user

  if EmailDelivery.column_names.include?('campaign')
    validates_presence_of :user_id, :campaign, :sent_at
    validates_numericality_of :user_id
  else
    belongs_to :campaign, class_name: :EmailCampaign, foreign_key: :email_campaign_id
    validates_presence_of :user_id, :email_campaign_id, :sent_at
    validates_numericality_of :user_id, :email_campaign_id
  end

  scope :for_campaign, ->(name) { joins(:campaign).where(email_campaigns: {name: name}) }

  before_validation do
    self.sent_at ||= Time.now
  end
end

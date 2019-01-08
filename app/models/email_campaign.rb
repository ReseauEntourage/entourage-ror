class EmailCampaign < ActiveRecord::Base
  has_many :deliveries, class_name: :EmailDelivery, foreign_key: :email_campaign_id
end

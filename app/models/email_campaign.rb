class EmailCampaign < ApplicationRecord
  has_many :deliveries, class_name: :EmailDelivery, foreign_key: :email_campaign_id
end

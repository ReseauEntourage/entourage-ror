require 'sidekiq/api'

class SyncSfEntrepriseParticipantJob
  include Sidekiq::Worker

  def perform sf_campaign_id, user_id
    user = User.find(user_id)
    sf_contact_id = SalesforceServices::Contact.new(user).find_id

    SalesforceServices::SfEntrepriseJoinRequest.new(
      sf_campaign_id: sf_campaign_id,
      sf_contact_id: sf_contact_id
    ).upsert
  end

  def self.perform_later sf_campaign_id, user_id
    perform_async(sf_campaign_id, user_id)
  end
end

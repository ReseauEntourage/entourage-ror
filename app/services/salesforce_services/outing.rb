module SalesforceServices
  class Outing < Connect
    def initialize instance
      super(
        interface: OutingTableInterface.new(instance: instance),
        instance: instance
      )
    end

    def is_synchable?
      return false if instance.online
      return false unless user = instance.user
      return false unless instance.address.present?

      user.team? || user.ambassador?
    end

    def upsert
      (find_id || super).tap do |campaign_id|
        setup_campaign_member_statuses_on_campaign!(campaign_id)
      end
    end

    def destroy
      return unless id = find_id

      client.update(interface.table_name, Id: id, Status: "Aborted")
    end

    def updatable_fields
      [:status, :title, :metadata, :sf_category, :sf_category_list]
    end

    def setup_campaign_member_statuses_on_campaign! campaign_id
      SalesforceServices::CampaignMember.setup_campaign_statuses(campaign_id)
    end
  end
end

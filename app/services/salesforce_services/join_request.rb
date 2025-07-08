module SalesforceServices
  class JoinRequest < Connect
    attr_accessor :user, :outing

    def initialize instance
      raise ArgumentError.new("joinable should be a outing") unless instance.outing?

      @user = instance.user
      @outing = ::Outing.find(instance.joinable_id)

      super(
        interface: JoinRequestTableInterface.new(instance: instance),
        instance: instance
      )
    end

    def is_synchable?
      instance.outing?
    end

    def upsert
      return unless contact_id = find_or_initialize_contact_id
      return unless campaign_id = find_or_initialize_campaign_id

      upsert_from_fields(
        interface.mapped_fields.merge({
          "ContactId" => contact_id,
          "CampaignId" => campaign_id,
          "Status" => "Inscrit"
        })
      )
    end

    def destroy
      return unless id = find_id

      client.update(interface.table_name, Id: id, Status: "A annulé")
    end

    def updatable_fields
      [:status]
    end

    private

    def find_or_initialize_contact_id
      contact_id || contact_id!
    end

    def contact_id
      @contact_id ||= SalesforceServices::Contact.new(user).find_id
    end

    def contact_id!
      Contact.new(user).upsert
    end

    def find_or_initialize_campaign_id
      campaign_id || campaign_id!
    end

    def campaign_id
      @campaign_id ||= SalesforceServices::Outing.new(outing).find_id
    end

    def campaign_id!
      SalesforceServices::Outing.new(outing).upsert
    end
  end
end

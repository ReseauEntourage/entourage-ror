module SalesforceServices
  class SfEntrepriseJoinRequest < Connect
    attr_accessor :user, :outing

    def initialize sf_campaign_id:, sf_contact_id:
      @sf_campaign_id = sf_campaign_id
      @sf_contact_id = sf_contact_id
    end

    def upsert
      upsert_from_fields({
        "ContactId" => @sf_contact_id,
        "CampaignId" => @sf_campaign_id,
        "Status" => "Participé",
        "Droit_l_image__c" => true,
      })
    end

    def interface
      @interface ||= OpenStruct.new(
        table_name: "CampaignMember",
        external_id_key: :id,
        external_id_value: "JoinRequestId__c",
        mapped_fields: {}
      )
    end
  end
end

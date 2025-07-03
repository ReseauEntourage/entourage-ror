module SalesforceServices
  class JoinRequestTableInterface < TableInterface
    TABLE_NAME = "CampaignMember"

    INSTANCE_MAPPING = {
      status: "Status",
      campaign_id: "CampaignId",
      contact_id: "ContactId",
    }

    def initialize instance:
      super(table_name: TABLE_NAME, instance: instance)
    end

    def external_id_key
      :id
    end

    def external_id_value
      "JoinRequestId__c"
    end

    def mapping
      @mapping ||= MappingStruct.new(outing: instance)
    end

    def instance_mapping
      INSTANCE_MAPPING
    end

    MappingStruct = Struct.new(:join_request) do
      attr_accessor :join_request

      def initialize(join_request: nil)
        @join_request = join_request
      end

      def method_missing(method_name, *args, &block)
        if join_request.respond_to?(method_name)
          join_request.public_send(method_name, *args, &block)
        else
          raise NoMethodError, "Undefined method `#{method_name}` for #{self.class.name} and #{join_request.class.name}"
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        join_request.respond_to?(method_name, include_private) || super
      end

      def id
        join_request.id
      end

      def external_id
        join_request.id
      end

      def status
        return "A annulé" if join_request.cancelled?

        "Inscrit"
      end

      def campaign_id
        join_request.campaign_id
      end

      def contact_id
        join_request.contact_id
      end
    end
  end
end

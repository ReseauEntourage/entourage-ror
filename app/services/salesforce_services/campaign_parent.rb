module SalesforceServices
  class CampaignParent
    TABLE_NAME = 'Campaign'

    PAPOTAGE = 'papotage'

    CampaignParentStruct = Struct.new(:campaign_parent) do
      def initialize(campaign_parent: nil)
        @campaign_parent = campaign_parent
      end

      def upsert
        salesforce_config = SalesforceConfig.find_or_initialize_by(salesforce_id: @campaign_parent['Id'])
        salesforce_config.klass = TABLE_NAME
        salesforce_config.name = @campaign_parent['Name']
        salesforce_config.save
      end
    end

    class << self
      def client
        SalesforceServices::Connect.client
      end

      def campaign_parents
        @campaign_parents ||= client.query("SELECT Id, Name FROM #{TABLE_NAME} WHERE Est_une_campagne_principale__c = true")
      end

      def records
        SalesforceConfig.where(klass: TABLE_NAME)
      end

      def import
        campaign_parents.each do |campaign_parent|
          CampaignParentStruct.new(campaign_parent: campaign_parent).upsert
        end
      end

      def reimport
        records.delete_all.tap do
          import
        end
      end

      def find_by_similar_name name
        records
          .where("name ILIKE ?", "%#{name}%")
          .first
      end

      def find_for_outing outing
        return unless outing.respond_to?(:papotage?)
        return unless outing.papotage?

        find_by_similar_name(PAPOTAGE)
      end
    end
  end
end

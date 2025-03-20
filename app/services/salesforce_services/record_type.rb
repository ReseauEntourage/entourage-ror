module SalesforceServices
  class RecordType
    TABLE_NAME = "RecordType"

    DEVELOPER_NAME_USER_MAPPING = {
      ask_for_help: "Personne_preca",
      offer_help: "Riverain",
    }

    DEVELOPER_NAME_OUTING = "Campagne"

    RecordTypeStruct = Struct.new(:record_type) do
      def initialize(record_type: nil)
        @record_type = record_type
      end

      def upsert
        salesforce_config = SalesforceConfig.find_or_initialize_by(salesforce_id: @record_type["Id"])
        salesforce_config.klass = TABLE_NAME
        salesforce_config.developer_name = @record_type["DeveloperName"]
        salesforce_config.save
      end
    end

    class << self
      def client
        SalesforceServices::Connect.client
      end

      def import
        client.query("SELECT Id, DeveloperName FROM #{TABLE_NAME}").each do |record_type|
          RecordTypeStruct.new(record_type: record_type).upsert
        end
      end

      def find_by_developer_name developer_name
        SalesforceConfig.find_by_klass_and_developer_name(TABLE_NAME, developer_name)
      end

      def find_for_outing
        find_by_developer_name(DEVELOPER_NAME_OUTING)
      end

      def find_for_user user
        developer_name = user.is_ask_for_help? ? DEVELOPER_NAME_USER_MAPPING[:ask_for_help] : DEVELOPER_NAME_USER_MAPPING[:offer_help]

        find_by_developer_name(developer_name)
      end
    end
  end
end

module SalesforceServices
  class RecordType
    TABLE_NAME = 'RecordType'

    NAME_USER_MAPPING = {
      ask_for_help: 'Personne_preca',
      offer_help: 'Riverain',
    }

    NAME_OUTING = 'Campagne'

    RecordTypeStruct = Struct.new(:record_type) do
      def initialize(record_type: nil)
        @record_type = record_type
      end

      def upsert
        salesforce_config = SalesforceConfig.find_or_initialize_by(salesforce_id: @record_type['Id'])
        salesforce_config.klass = TABLE_NAME
        salesforce_config.name = @record_type['DeveloperName']
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

      def find_by_name name
        SalesforceConfig.find_by_klass_and_name(TABLE_NAME, name)
      end

      def find_for_outing
        find_by_name(NAME_OUTING)
      end

      def find_for_user user
        name = user.is_ask_for_help? ? NAME_USER_MAPPING[:ask_for_help] : NAME_USER_MAPPING[:offer_help]

        find_by_name(name)
      end
    end
  end
end

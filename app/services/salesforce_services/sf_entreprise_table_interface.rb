module SalesforceServices
  class SfEntrepriseTableInterface < TableInterface
    TABLE_NAME = "Account"

    INSTANCE_MAPPING = {
      id: "Id",
      name: "Name",
      type: "Type_org__c"
    }

    def initialize
      super(table_name: TABLE_NAME, instance: nil)
    end

    def instance_mapping
      INSTANCE_MAPPING
    end

    class << self
      def where_clause
        "Type_org__c = 'Entreprise' AND Statut_0_synchro_contacts__c = '🟢 Partenaire'"
      end

      def order_clause
        "Name ASC"
      end
    end
  end
end

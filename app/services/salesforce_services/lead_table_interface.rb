module SalesforceServices
  class LeadTableInterface < TableInterface
    TABLE_NAME = "Lead"

    def initialize instance:
      super(table_name: TABLE_NAME, instance: instance)
    end

    def external_id_key
      :phone
    end

    def external_id_value
      "ID_externe__c"
    end
  end
end

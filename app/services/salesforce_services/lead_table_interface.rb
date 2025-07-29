module SalesforceServices
  class LeadTableInterface < TableInterface
    TABLE_NAME = 'Lead'

    INSTANCE_MAPPING = {
    }

    def initialize instance:
      super(table_name: TABLE_NAME, instance: instance)
    end

    def external_id_key
      :phone
    end

    def external_id_value
      'ID_externe__c'
    end

    def instance_mapping
      INSTANCE_MAPPING
    end
  end
end

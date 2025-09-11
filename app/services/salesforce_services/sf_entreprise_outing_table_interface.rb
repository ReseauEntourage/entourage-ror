module SalesforceServices
  class SfEntrepriseOutingTableInterface < TableInterface
    TABLE_NAME = "Campaign"

    INSTANCE_MAPPING = {
      id: "Id",
      title: "Name"
    }

    def initialize sf_entreprise_id:
      @sf_entreprise_id = sf_entreprise_id

      super(table_name: TABLE_NAME, instance: nil)
    end

    def instance_mapping
      INSTANCE_MAPPING
    end

    def base_query
      super.where("Organisateur__c = '#{@sf_entreprise_id}'")
    end

    def count_records
      base_query.count.query.size
    end

    def records_attributes per: nil, page: nil
      results = base_query
        .select(instance_mapping.values.join(', '))
        .limit(per)
        .offset(page)
        .query

      # exclude attributes
      results.map { _1.to_h.except('attributes') }
    end

    def records per: nil, page: nil
      {
        data: records_attributes(per: per, page: page),
        total: count_records
      }
    end
  end
end

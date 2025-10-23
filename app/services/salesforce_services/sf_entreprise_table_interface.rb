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

    def base_query
      super
        .where("Type_org__c = 'Entreprise'")
        .where("Id IN (SELECT Organisateur__c FROM Campaign WHERE StartDate >= #{Date.today.strftime("%Y-%m-%d")} AND IsActive = true)")
        .order("Name ASC")
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

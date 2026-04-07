module SalesforceServices
  class SfEntrepriseOutingTableInterface < TableInterface
    TABLE_NAME = "Campaign"

    INSTANCE_MAPPING = {
      id: "Id",
      title: "Name",
      postal_code: "Code_postal__c",
      is_active: "IsActive",
      status: "Status",
      start_date: "StartDate",
      start_time: "Heure_de_d_but__c",
      end_date: "EndDate",
      end_time: "Heure_de_fin__c",
    }

    def initialize sf_entreprise_id:
      @sf_entreprise_id = sf_entreprise_id

      super(table_name: TABLE_NAME, instance: nil)
    end

    def instance_mapping
      INSTANCE_MAPPING
    end

    def base_query
      super
        .where("Organisateur__c = '#{@sf_entreprise_id}'")
        .where("StartDate >= #{Date.today.strftime("%Y-%m-%d")}")
        .where("IsActive = true")
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

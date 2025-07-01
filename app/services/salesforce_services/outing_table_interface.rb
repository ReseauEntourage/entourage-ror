module SalesforceServices
  class OutingTableInterface < TableInterface
    TABLE_NAME = "Campaign"

    INSTANCE_MAPPING = {
      id: "Id_app_de_l_event__c",
      address: "Adresse_de_l_v_nement__c",
      antenne: "Antenne__c",
      title: "Name",
      postal_code: "Code_postal__c",
      starts_date: "StartDate",
      starts_time: "Heure_de_d_but__c",
      ends_date: "EndDate",
      ends_time: "Heure_de_fin__c",
      ongoing?: "IsActive",
      not_ongoing?: "Status",
      status: "Statut_d_Entourage__c",
      reseau: "R_seaux__c",
      record_type_id: "RecordTypeId",
      type: "Type",
      type_public: "Public_sensibilis__c",
      type_evenement: "Type_evenement__c"
    }

    def initialize instance:
      super(table_name: TABLE_NAME, instance: instance)
    end

    def external_id_key
      :id
    end

    def external_id_value
      "OutingId__c"
    end

    def mapping
      @mapping ||= MappingStruct.new(outing: instance)
    end

    def instance_mapping
      INSTANCE_MAPPING
    end

    MappingStruct = Struct.new(:outing) do
      attr_accessor :outing

      def initialize(outing: nil)
        @outing = outing
      end

      def method_missing(method_name, *args, &block)
        if outing.respond_to?(method_name)
          outing.public_send(method_name, *args, &block)
        else
          raise NoMethodError, "Undefined method `#{method_name}` for #{self.class.name} and #{outing.class.name}"
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        outing.respond_to?(method_name, include_private) || super
      end

      def id
        outing.id
      end

      def external_id
        outing.id
      end

      def address
        outing.address
      end

      def antenne
        outing.sf.from_address_to_antenne
      end

      def title
        # city // title - starts_at
        "#{outing.city} // #{outing.title} - #{starts_date}"
      end

      def postal_code
        outing.postal_code
      end

      def starts_date
        outing.starts_at.strftime("%Y-%m-%d")
      end

      def starts_time
        outing.starts_at.strftime("%H:%M:%S")
      end

      def ends_date
        outing.ends_at.strftime("%Y-%m-%d")
      end

      def ends_time
        outing.ends_at.strftime("%H:%M:%S")
      end

      def ongoing?
        outing.ongoing?
      end

      def not_ongoing?
        ! outing.ongoing?
      end

      def status
        # only outings created by staff or ambassadors are sync with salesforce
        "Organisateur"
      end

      def reseau
        "Entourage"
      end

      def record_type_id
        return unless record_type = SalesforceServices::RecordType.find_for_outing

        record_type.salesforce_id
      end

      def type
        "Event"
      end

      def type_public
        "Grand public"
      end

      def type_evenement
        "Evenement de convivialité"
      end
    end
  end
end

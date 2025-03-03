module SalesforceServices
  class Outing < Connect
    TABLE_NAME = "Campaign"

    UPDATABLE_FIELDS = [:status, :title, :metadata]

    RESEAU = "Entourage"
    STATUS_ENTOURAGE = "Organisateur"
    TYPE = "Event"
    TYPE_EVENEMENT = "Evenement de convivialité"

    def find_id_by_outing outing
      return unless outing.ongoing?

      return unless attributes = find_by_external_id(outing.id)
      return unless attributes.any?

      attributes["Id"]
    end

    def update outing
      client.update(TABLE_NAME, Id: find_id_by_outing(outing), **instance_to_hash(outing))
    end

    def upsert outing
      find_id_by_outing(outing) || client.upsert!(TABLE_NAME, "OutingId__C", "OutingId__C": outing.id, **instance_to_hash(outing))
    end

    def destroy outing
      client.update(TABLE_NAME, Id: find_id_by_outing(outing), Status: true)
    end

    def updatable_fields
      UPDATABLE_FIELDS
    end

    def find_by_external_id outing_id
      client.query("select Id from #{TABLE_NAME} where OutingId__C = #{outing_id}").first
    end

    private

    def instance_to_hash outing
      # Impact__c                    =>
      # Organisateur__c              =>
      {
        "Adresse_de_l_v_nement__c" => outing.address,
        "Antenne__c" => antenne(outing),
        "Name" => outing.title,
        "Code_postal__c" => outing.postal_code,
        "StartDate" => outing.starts_at.strftime("%Y-%m-%d"),
        "Heure_de_d_but__c" => outing.starts_at.strftime("%H:%M:%S"),
        "EndDate" => outing.ends_at.strftime("%Y-%m-%d"),
        "Heure_de_fin__c" => outing.ends_at.strftime("%H:%M:%S"),
        "Id_app_de_l_event__c" => outing.id,
        "IsActive" => outing.ongoing?,
        "Status" => !outing.ongoing?,
        "Statut_d_Entourage__c" => STATUS_ENTOURAGE, # only outings created by staff or ambassadors are sync with salesforce
        "R_seaux__c" => RESEAU,
        "RecordTypeId" => record_type_id,
        "Type" => TYPE,
        "Type_evenement__c" => TYPE_EVENEMENT
      }
    end

    def antenne outing
      outing.sf.from_address_to_antenne
    end

    def record_type_id
      return unless record_type = SalesforceServices::RecordType.find_for_outing

      record_type.salesforce_id
    end
  end
end

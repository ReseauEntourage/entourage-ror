module SalesforceServices
  class User < Connect
    def initialize instance
      super(
        interface: UserTableInterface.new(instance: instance),
        instance: instance
      )
    end

    def is_synchable?
      instance.address.present?
    end

    def upsert
      contact_id = if lead_id.present?
        contact_update!(contact_id)
      else
        contact_id!
      end

      upsert_from_fields(
        interface.mapped_fields.merge({
          "Prospect__c" => lead_id,
          "Contact__c" => contact_id
        })
      )
    end

    def destroy
      client.update(interface.table_name, Id: find_id, Status__c: "supprimé")
    end

    def updatable_fields
      [:validation_status, :first_name, :last_name, :email, :phone, :goal, :targeting_profile, :status, :deleted, :last_sign_in_at]
    end

    private

    def lead_id
      @lead_id ||= Lead.new(instance).find_id
    end

    def contact_id
      @contact_id ||= Contact.new(instance).find_id
    end

    def contact_id!
      Contact.new(instance).upsert
    end

    def contact_update! contact_id
      Contact.new(instance).update_from_id(contact_id)
    end
  end
end

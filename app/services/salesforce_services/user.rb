module SalesforceServices
  class User < Connect
    TABLE_NAME = "Contact"

    def id user
      return unless attributes = find_by_external_id(user.id)
      return unless attributes.any?

      attributes["Id"]
    end

    def find_by_external_id user_id
      client.query("select Id from #{TABLE_NAME} where ID_externe__c = '#{user_id}'").first
    end

    def create user
      client.create(TABLE_NAME, user_to_hash(user))
    end

    def update user
      client.update(TABLE_NAME, Id: id(user), **user_to_hash(user))
    end

    def upsert user
      client.upsert(
        TABLE_NAME,
        "ID_externe__c",
        "ID_externe__c": user.id,
        **user_to_hash(user)
      )
    end

    def destroy user
      client.destroy(TABLE_NAME, id(user))
    end

    # helpers

    def picklist_values type
      client.picklist_values(TABLE_NAME, type)
    end

    def user_to_hash user
      {
        "FirstName" => user.first_name,
        "LastName" => user.last_name,
        "Email" => user.email,
        "Phone" => user.phone,
        "RecordTypeId" => user.is_ask_for_help? ? "012Aa000001EmAfIAK" : "012Aa000001HBL3IAO",
        "Antenne__c" => "National",
        "Reseaux__c" => "Entourage",
        # "Statut__c" => user.sf_status,
        # "Departement__c" => user.departement,
      }
    end
  end
end

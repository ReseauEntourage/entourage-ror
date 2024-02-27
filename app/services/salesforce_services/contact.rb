module SalesforceServices
  class Contact < Connect
    TABLE_NAME = "Contact"

    def find_id_by_user user
      return unless user.validated?

      return unless attributes = find_by_phone(user.phone)
      return unless attributes.any?

      attributes["Id"]
    end

    def find_by_phone phone
      client.query("select Id from #{TABLE_NAME} where Phone = '#{phone}'").first
    end

    def upsert user
      find_id_by_user(user) || client.upsert(TABLE_NAME, "Phone", "Phone": user.phone, user_to_hash(user))
    end

    private

    def user_to_hash user
      {
        "FirstName" => user.first_name,
        "LastName" => user.last_name,
        "Email" => user.email,
        "Phone" => user.phone,
        "RecordTypeId" => user.is_ask_for_help? ? "012Aa000001EmAfIAK" : "012Aa000001HBL3IAO",
        "Antenne__c" => antenne(user),
        "Reseaux__c" => "Entourage",
      }
    end

    def antenne user
      user.sf.from_address_to_antenne
    end
  end
end

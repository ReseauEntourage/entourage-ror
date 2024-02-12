module SalesforceServices
  class Lead < Connect
    TABLE_NAME = "Lead"

    def find_id_by_user user
      return unless user.validated?

      return unless attributes = find_by_phone(user.phone)
      return unless attributes.any?

      attributes["Id"]
    end

    def find_by_phone phone
      client.query("select Id from #{TABLE_NAME} where Phone = '#{phone}'").first
    end
  end
end

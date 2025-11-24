module SalesforceServices
  class Contact < Connect
    def initialize instance
      super(
        interface: ContactTableInterface.new(instance: instance),
        instance: instance
      )
    end

    def find_id
      return unless instance.validated?

      super
    end

    def find_by_external_id
      unformatted_phone = Phone::PhoneBuilder.new(phone: instance.phone).unformat

      client.query("select Id from #{interface.table_name} where Phone = '#{instance.phone}' or Phone = '#{unformatted_phone}'").first
    end

    def upsert
      find_id || super
    end
  end
end

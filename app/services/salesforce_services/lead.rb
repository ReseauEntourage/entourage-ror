module SalesforceServices
  class Lead < Connect
    def initialize instance
      super(
        interface: LeadTableInterface.new(instance: instance),
        instance: instance
      )
    end

    def find_id
      return unless instance.validated?

      super
    end

    def find_by_external_id
      client.query("select Id from #{interface.table_name} where Phone = '#{instance.phone}'").first
    end
  end
end

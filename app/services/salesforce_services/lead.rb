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
      clauses = ["Phone = '#{instance.phone}'"]
      clauses << "Email = '#{instance.email.downcase}'" if instance.email.present?

      client.query(%(
        select Id
        from #{interface.table_name}
        where #{clauses.join(' OR ')}
      )).first
    end
  end
end

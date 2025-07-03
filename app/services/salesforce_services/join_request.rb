module SalesforceServices
  class JoinRequest < Connect
    def initialize instance
      super(
        interface: JoinRequestTableInterface.new(instance: instance),
        instance: instance
      )
    end

    def is_synchable?
      instance.outing?
    end

    def upsert
      find_id || super
    end

    def destroy
      return unless id = find_id

      client.update(interface.table_name, Id: id, Status: "Aborted")
    end

    def updatable_fields
      [:status, :title, :metadata, :sf_category, :sf_category_list]
    end
  end
end

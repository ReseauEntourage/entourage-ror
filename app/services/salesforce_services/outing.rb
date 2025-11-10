module SalesforceServices
  class Outing < Connect
    def initialize instance
      super(
        interface: OutingTableInterface.new(instance: instance),
        instance: instance
      )
    end

    def is_synchable?
      return false if instance.online
      return false unless user = instance.user
      return false unless instance.address.present?

      user.team? || user.ambassador?
    end

    def upsert
      (find_id || super).tap do
        # ensure members (organizator) are synchronized
        instance.join_requests.each do |join_request|
          join_request.sf.upsert unless join_request.salesforce_id.present?
        end
      end
    end

    def destroy
      return unless id = find_id

      client.update(interface.table_name, Id: id, Status: 'Aborted')
    end

    def updatable_fields
      [:status, :title, :metadata, :sf_category, :sf_category_list]
    end
  end
end

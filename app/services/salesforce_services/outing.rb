module SalesforceServices
  class Outing < Connect
    def initialize instance
      super(
        interface: OutingTableInterface.new(instance: instance),
        instance: instance
      )
    end

    def is_synchable? instance
      return false if instance.online
      return false unless user = instance.user
      return false unless instance.address.present?

      user.team?
    end

    def find_id
      return unless instance.ongoing?

      super
    end

    def upsert
      find_id || super
    end

    def updatable_fields
      [:status, :title, :metadata]
    end
  end
end

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

      user.team?
    end

    def upsert
      find_id || super
    end

    def updatable_fields
      [:status, :title, :metadata, :sf_category, :sf_category_list]
    end
  end
end

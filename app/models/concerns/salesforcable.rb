module Salesforcable
  extend ActiveSupport::Concern

  included do
    after_commit :sync_salesforce, if: :saved_changes?
  end

  SalesforceStruct = Struct.new(:instance) do
    def initialize(instance: nil)
      service_class = "SalesforceServices::#{instance.class.name}"
      raise ArgumentError.new("class #{service_class} does not exist") unless @service = service_class.safe_constantize

      @service = @service.new
      @instance = instance
    end

    def show
      @service.find_by_external_id(@instance.id)
    end

    def create
      @service.create(@instance)
    end

    def update
      @service.update(@instance)
    end

    def upsert
      @service.upsert(@instance)
    end

    def destroy
      @service.destroy(@instance)
    end

    def updatable_fields
      @service.updatable_fields
    end

    def from_address_to_antenne
      return "National" unless @instance.present? && @instance.respond_to?(:address)

      address = @instance.address

      return "National" unless address.present? && address.departement.present?

      return "Paris" if address.departement == "75"
      return "Lille" if address.departement == "59"
      return "Lyon" if address.departement == "69"
      return "Rennes" if address.departement == "35"
      return "Seine Saint Denis" if address.departement == "93"
      return "Hauts de Seine" if address.departement == "92"
      return "Marseille" if address.departement == "13"
      return "IDF" if address.departement == "77" || address.departement == "78" || address.departement == "91" || address.departement == "94" || address.departement == "95"
      return "Lorient" if address.departement == "56"
      return "Nantes" if address.departement == "44"
      return "Bordeaux" if address.departement == "33"
      return "Saint Etienne" if address.departement == "42"

      "Hors zone"
    end
  end

  def salesforce
    @salesforce ||= SalesforceStruct.new(instance: self)
  end

  def sync_salesforce
    return unless last_sign_in_at.present?

    if has_attribute?(:deleted)
      return SalesforceJob.perform_later(id, "destroy") if saved_change_to_deleted? && deleted?
    end

    if has_attribute?(:status)
      return SalesforceJob.perform_later(id, "destroy") if saved_change_to_status? && status == "deleted"
    end

    return unless sf.updatable_fields.any? { |field| saved_change_to_attribute?(field) }

    SalesforceJob.perform_later(id, "upsert")
  end

  alias_method :sf, :salesforce
end

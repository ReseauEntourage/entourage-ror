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
      return "National" unless @instance.present? && @instance.respond_to?(:departement)

      departement = @instance.departement

      return "National" unless departement.present?

      return "Paris" if departement == "75"
      return "Lille" if departement == "59"
      return "Lyon" if departement == "69"
      return "Rennes" if departement == "35"
      return "Seine Saint Denis" if departement == "93"
      return "Hauts de Seine" if departement == "92"
      return "Marseille" if departement == "13"
      return "IDF" if departement == "77" || departement == "78" || departement == "91" || departement == "94" || departement == "95"
      return "Lorient" if departement == "56"
      return "Nantes" if departement == "44"
      return "Bordeaux" if departement == "33"
      return "Saint-Etienne" if departement == "42"

      "Hors zone"
    end
  end

  def salesforce
    @salesforce ||= SalesforceStruct.new(instance: self)
  end

  def sync_salesforce
    return unless address.present?

    if has_attribute?(:deleted)
      return SalesforceJob.perform_later(id, "destroy") if saved_change_to_deleted? && deleted?
    end

    if has_attribute?(:status)
      return SalesforceJob.perform_later(id, "destroy") if saved_change_to_status? && status == "deleted"
    end

    return unless salesforce_id.nil? || sf.updatable_fields.any? { |field| saved_change_to_attribute?(field) }

    SalesforceJob.perform_later(id, "upsert")
  end

  alias_method :sf, :salesforce
end

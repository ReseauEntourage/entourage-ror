module Salesforcable
  extend ActiveSupport::Concern

  included do
    after_commit :sync_salesforce, if: :saved_changes?
  end

  SalesforceStruct = Struct.new(:instance) do
    def initialize(instance: nil)
      @service = SalesforceServices::User.new

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
  end

  def salesforce
    @salesforce ||= SalesforceStruct.new(instance: self)
  end

  def sync_salesforce
    return sync_salesforce_destroy if saved_change_to_validation_status? && deleted?

    return unless [:validation_status, :first_name, :last_name, :email, :phone, :goal, :targeting_profile].any? { |field| saved_change_to_attribute?(field) }

    SalesforceJob.perform_later(id, :upsert)
  end

  def sync_salesforce_destroy
    SalesforceJob.perform_later(id, :destroy)
  end

  alias_method :sf, :salesforce
end

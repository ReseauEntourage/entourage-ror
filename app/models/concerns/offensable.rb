module Offensable
  extend ActiveSupport::Concern

  included do
    has_one :openai_request, as: :instance

    after_save :offense_on_save, :if => :offensable_field_changed?
  end

  def build_openai_request(attributes = {})
    super(attributes.merge(instance_class: self.class.name))
  end

  def offensable_field_changed?
    previous_changes.slice(:content).present?
  end

  def offense
    @offense ||= OffenseStruct.new(instance: self)
  end

  def offense_on_save
    offense.on_save
  end

  OffenseStruct = Struct.new(:instance) do
    def initialize instance: nil
      @instance = instance
    end

    def on_save
      ensure_openai_request_exists!
    end

    def ensure_openai_request_exists!
      return if @instance.openai_request

      @instance.build_openai_request(module_type: :offense).save!
    end
  end
end

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
    if respond_to?(:messageable)
      return if messageable.respond_to?(:conversation?) && messageable.conversation?
    end

    offense.on_save if SensitiveWordsService.has_match?(content, :all, SensitiveWord::OFFENSABLE_CATEGORIES)
  end

  def is_offensible!
    update_column(:status, :offensible)
  end

  def is_offensive!
    update_column(:status, :offensive)
  end

  def is_not_offensive!
    update_column(:status, :active)
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

module Matchable
  extend ActiveSupport::Concern

  included do
    after_save :match_on_save, :if => :matchable_field_changed?

    has_one :openai_request, as: :instance
    has_many :matchings, as: :instance
    has_many :matches, through: :matchings, source: :match
  end

  def matchings_with_notifications
    matchings.with_notifications_for_user(user)
  end

  def build_openai_request(attributes = {})
    super(attributes.merge(instance_class: self.class.name))
  end

  def matchable_field_changed?
    previous_changes.slice(:title, :name, :description).present?
  end

  def match
    @match ||= MatchStruct.new(instance: self)
  end

  def match_on_save
    match.on_save
  end

  MatchStruct = Struct.new(:instance) do
    def initialize instance: nil
      @instance = instance
    end

    def on_save
      ensure_openai_request_exists!
    end

    def ensure_openai_request_exists!
      return if @instance.openai_request

      @instance.build_openai_request.save!
    end
  end
end

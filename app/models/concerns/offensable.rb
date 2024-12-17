module Offensable
  extend ActiveSupport::Concern

  alias_attribute :name, :content

  FIELDS = {
    chat_messages: "content"
  }

  included do
    has_one :openai_request, as: :instance

    after_commit :check_offense, if: :check_offense?
  end

  private

  def build_openai_request(attributes = {})
    super(attributes.merge(instance_class: self.class.name))
  end

  def check_offense
    build_openai_request(module_type: :offense).save!
  end

  def check_offense?
    key = self.class.table_name.to_sym

    return false unless FIELDS.has_key?(key)

    previous_changes.keys.include?(FIELDS[key])
  end
end

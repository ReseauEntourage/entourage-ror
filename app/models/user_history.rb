class UserHistory < ApplicationRecord
  belongs_to :user
  belongs_to :updater, class_name: :User

  attribute :metadata, :jsonb_with_schema

  scope :blocked, -> { where(kind: 'block').order('user_histories.created_at desc') }
  scope :anonymized, -> { where(kind: 'anonymized') }

  def metadata= value
    value = add_metadata_schema_urn(value)
    super(value)
  end

  def add_metadata_schema_urn value
    value = {} if value.nil?
    value['$id'] = "urn:user_history:#{kind}:metadata" if kind
    value
  end

  def self.json_schema urn
    JsonSchemaService.base do
      case urn
      when 'block:metadata', 'unblock:metadata'
        {
          cnil_explanation: { type: :string },
          temporary: { type: :boolean }
        }
      when 'signal-user:metadata', 'unblock:metadata'
        {
          message: { type: :string }
        }
      else
        {}
      end
    end
  end

  def cnil_explanation
    return unless self[:metadata]

    self[:metadata][:cnil_explanation]
  end
end

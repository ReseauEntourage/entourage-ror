class UserHistory < ApplicationRecord
  belongs_to :user
  belongs_to :user, foreign_key: :updater_id

  attribute :metadata, :jsonb_with_schema

  scope :blocked, -> { where(kind: 'block').order('user_histories.created_at desc') }

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
          cnil_explanation: { type: :string }
        }
      end
    end
  end
end

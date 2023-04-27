class UserHistory < ApplicationRecord
  belongs_to :user
  belongs_to :updater, class_name: :User, required: false

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
      when 'spam-detection:metadata'
        {
          messageable_id: { type: :integer },
          messageable_type: { type: :string }
        }
      when 'block:metadata', 'unblock:metadata'
        {
          cnil_explanation: { type: :string },
          temporary: { type: :boolean }
        }
      when 'spam-alert:metadata'
        { message: { type: :string } }
      when 'deleted:metadata'
        {
          email_was: { type: :string }
        }
      when 'signal-action:metadata'
        {
          message: { type: :string },
          entourage_id: { type: :integer }
        }
      when 'signal-user:metadata'
        {
          message: { type: :string },
          signals: { type: :string }
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

  def message
    return unless self[:metadata]

    self[:metadata][:message]
  end

  def self.spam_not_reported? chat_message
    return true if chat_message.spams.empty?

    UserHistory.where(
      user_id: chat_message.user_id,
      kind: 'spam-detection'
    ).where(
      "(metadata ->> 'messageable_id')::integer IN (?) and metadata ->> 'messageable_type' = 'Entourage'",
      chat_message.spams.map(&:messageable_id)
    ).empty?
  end
end

class Solicitation < Entourage
  include Actionable
  include Sectionable

  default_scope { where(group_type: :action, entourage_type: :ask_for_help).order(feed_updated_at: :desc) }

  after_create :after_create_build_moderation

  def after_create_build_moderation
    return if recipient_consent_obtained == nil

    moderation || build_moderation
    moderation.action_recipient_consent_obtained = {
      true  => 'Oui',
      false => 'Non',
    }[recipient_consent_obtained]

    moderation.save
  end

  def parent_chat_messages
    chat_messages.where(ancestry: nil)
  end

  attr_accessor :recipient_consent_obtained

  def recipient_consent_obtained= recipient_consent_obtained
    @recipient_consent_obtained = ActiveModel::Type::Boolean.new.cast(recipient_consent_obtained)
  end
end

class EmailPreference < ApplicationRecord
  belongs_to :user
  belongs_to :category, class_name: :EmailCategory, foreign_key: :email_category_id

  validates :user, :email_category_id, presence: true
  validates :subscribed, inclusion: { in: [true, false] }

  include CustomTimestampAttributesForUpdate

  before_save :track_subscription_change
  after_commit :sync_newsletter!, if: :sync_newsletter?

  def newsletter_contact
    NewsletterServices::Contact.new(email: email, zone: newsletter_zone, status: newsletter_status)
  end

  def newsletter_zone
    NewsletterServices::Contact.zone_for_address(user.address)
  end

  def newsletter_status
    NewsletterServices::Contact.status_for_user(user)
  end

  def self.for_category category
    where(email_category_id: EmailPreferencesService.category_id(category))
  end

  private

  def track_subscription_change
    if subscribed_changed? && !subscription_changed_at_changed?
      @custom_timestamp_attributes_for_update = ["subscription_changed_at"]
    end
  end

  class << self
    def sync_newsletter email_preference_id
      email_preference = EmailPreference.find(email_preference_id)

      return unless email_preference.email_category_id == EmailPreferencesService.category_id('newsletter')
      return unless email_preference.user
      return unless email_preference.user.email

      return email_preference.contact.create if email_preference.subscribed

      email_preference.contact.delete
    end
  end

  def sync_newsletter?
    return false unless previous_changes.keys.include? 'subscribed'

    category.name.in? ['newsletter']
  end

  def sync_newsletter!
    AsyncService.new(self.class).sync_newsletter(self.id)
  end
end


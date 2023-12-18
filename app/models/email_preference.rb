class EmailPreference < ApplicationRecord
  belongs_to :user
  belongs_to :category, class_name: :EmailCategory, foreign_key: :email_category_id

  validates :user, :email_category_id, presence: true
  validates :subscribed, inclusion: { in: [true, false] }

  include CustomTimestampAttributesForUpdate
  before_save :track_subscription_change
  after_commit :sync_mailchimp_subscription_status_async


  def self.for_category category
    where(email_category_id: EmailPreferencesService.category_id(category))
  end

  private

  def track_subscription_change
    if subscribed_changed? && !subscription_changed_at_changed?
      @custom_timestamp_attributes_for_update = ["subscription_changed_at"]
    end
  end

  def sync_mailchimp_subscription_status_async
    return unless EmailPreferencesService.enable_mailchimp_callback?
    return unless previous_changes.keys.include? 'subscribed'
    return unless category.name.in? ['newsletter']
    AsyncService.new(EmailPreferencesService)
      .sync_mailchimp_subscription_status(self)
  end
end

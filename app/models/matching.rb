class Matching < ApplicationRecord
  belongs_to :instance, polymorphic: true
  belongs_to :match, polymorphic: true

  attr_accessor :inapp_notification_exists

  scope :with_notifications_for_user, -> (user) {
    joins("LEFT JOIN inapp_notifications ON inapp_notifications.instance = matchings.instance_type AND inapp_notifications.instance_id = matchings.instance_id AND inapp_notifications.user_id = #{user.id}")
      .select(
        'matchings.*',
        'CASE WHEN inapp_notifications.id IS NOT NULL THEN true ELSE false END AS inapp_notification_exists'
      )
  }

  def inapp_notification_exists? user
    InappNotification.exists?(user: user, instance: instance_type, instance_id: instance_id, context: :matching)
  end
end

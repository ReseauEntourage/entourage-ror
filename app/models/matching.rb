class Matching < ApplicationRecord
  belongs_to :instance, polymorphic: true
  belongs_to :match, polymorphic: true

  attr_accessor :inapp_notification_exists_virtual

  scope :with_notifications_for_user, -> (user) {
    joins(%(
      LEFT JOIN inapp_notifications ON
        (inapp_notifications.context = 'matching_on_create' OR inapp_notifications.context = 'matching_on_forced_create') AND
        inapp_notifications.instance_baseclass = matchings.match_type AND
        inapp_notifications.instance_id = matchings.match_id AND
        inapp_notifications.user_id = #{user.id}
      ))
      .select(
        'matchings.*',
        'CASE WHEN inapp_notifications.id IS NOT NULL THEN true ELSE false END AS inapp_notification_exists'
      )
  }

  def inapp_notification_exists
    return @inapp_notification_exists_virtual unless @inapp_notification_exists_virtual.nil?

    read_attribute(:inapp_notification_exists)
  end

  def inapp_notification_exists? user
    InappNotification.exists?(user: user, instance_baseclass: instance_type, instance_id: instance_id, context: :matching)
  end
end

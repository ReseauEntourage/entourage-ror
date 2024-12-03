class Matching < ApplicationRecord
  belongs_to :instance, polymorphic: true
  belongs_to :match, polymorphic: true

  attr_accessor :inapp_notification_created_at_virtual

  scope :with_notifications_for_user, -> (user) {
    joins(%(
      LEFT JOIN inapp_notifications ON
        (inapp_notifications.context = 'matching_on_create' OR inapp_notifications.context = 'matching_on_forced_create') AND
        inapp_notifications.instance_baseclass = matchings.match_type AND
        inapp_notifications.instance_id = matchings.match_id AND
        inapp_notifications.user_id = #{user.id}
      )
    )
  }

  def inapp_notification_created_at
    return @inapp_notification_created_at_virtual unless @inapp_notification_created_at_virtual.nil?

    read_attribute(:inapp_notification_created_at)
  end

  def inapp_notifications
    InappNotification.where(user: instance.user, instance_baseclass: match_type, instance_id: match_id, context: [:matching_on_create, :matching_on_forced_create])
  end
end

module Preloaders
  module InappNotification
    # une requête par type d'instance au lieu d'une par notification (@see InappNotification#record)
    def self.preload_records notifications
      # V1::InappNotificationSerializer#image_url shows the sender avatar of these notifications, not their record
      notifications = notifications.to_a.reject do |notification|
        notification.sender_id.present? && (notification.chat_message_on_create? || notification.join_request?)
      end

      notifications.reject(&:post?).select(&:record_class).group_by(&:record_class).each do |klass, group|
        records = klass.unscoped.where(id: group.map(&:instance_id).uniq).index_by(&:id)

        group.each { |notification| notification.record = records[notification.instance_id] }
      end

      # @see V1::InappNotificationSerializer#image_url_for_neighborhood_post, #image_url_for_outing_post
      posts = notifications.select(&:post?).map(&:post).compact
      ActiveRecord::Associations::Preloader.new(records: posts, associations: :messageable).call
    end
  end
end

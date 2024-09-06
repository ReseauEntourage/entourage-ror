class PushNotificationService
  def initialize
  end

  def send_notification(sender, i18nstruct_object, i18nstruct_content, users, referent, referent_id, extra={})
    users.each do |user|
      next if user.blocked?
      next unless extra[:welcome] || NotificationPermission.notify_push?(user, referent, referent_id)

      object = i18nstruct_object.to(user.lang)
      content = i18nstruct_content.to(user.lang)

      UserServices::UserApplications.new(user: user).app_tokens.each do |token|
        NotificationJob.perform_later(sender, object, content, token.push_token, user.community.slug, extra, badge(user))
      end
    end
  end

  private

  def badge(user)
    0
  end
end

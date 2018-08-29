class NewJoinRequestNotifyJob < ActiveJob::Base
  def perform(joinable_type, joinable_id, user_id, type, message)
    user = User.find(user_id)
    joinable = joinable_type.constantize.find(joinable_id)
    recipients = [joinable.user]
    push_message = message || default_message(joinable)
    PushNotificationService.new.send_notification(UserPresenter.new(user: user).display_name,
                                                  "Demande en attente",
                                                  push_message,
                                                  recipients,
                                                  {joinable_id: joinable.id,
                                                   joinable_type: joinable_type,
                                                   group_type: joinable.group_type,
                                                   type: type,
                                                   user_id: user.id})
  end

  def default_message(group)
    object_name = GroupService.name(group)
    object_title = " : #{group.title}" if group.respond_to?(:title)
    "Un nouveau membre souhaite rejoindre votre #{object_name}#{object_title}"
  end
end
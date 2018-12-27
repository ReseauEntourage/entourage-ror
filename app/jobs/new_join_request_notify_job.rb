class NewJoinRequestNotifyJob < ActiveJob::Base
  def perform(joinable_type, joinable_id, user_id)
    user = User.find(user_id)
    joinable = joinable_type.constantize.find(joinable_id)
    recipients = [joinable.user]

    user_name = UserPresenter.new(user: user).display_name
    object_name = GroupService.name(joinable)
    message = "#{user_name} souhaite rejoindre votre #{object_name}"

    object = joinable.respond_to?(:title) ? joinable.title : "Demande en attente"

    PushNotificationService.new.send_notification(user_name,
                                                  object,
                                                  message,
                                                  recipients,
                                                  {joinable_id: joinable.id,
                                                   joinable_type: joinable_type,
                                                   group_type: joinable.group_type,
                                                   type: 'NEW_JOIN_REQUEST',
                                                   user_id: user.id})
  end
end

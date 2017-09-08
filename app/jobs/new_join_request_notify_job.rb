class NewJoinRequestNotifyJob < ActiveJob::Base
  def perform(joinable_type, joinable_id, user_id, type, message)
    user = User.find(user_id)
    joinable = joinable_type.constantize.find(joinable_id)
    recipients = [joinable.user]
    push_message = message || default_message(joinable_type: joinable_type, name: joinable.try(:title))
    PushNotificationService.new.send_notification(UserPresenter.new(user: user).display_name,
                                                  "Demande en attente",
                                                  push_message,
                                                  recipients,
                                                  {joinable_id: joinable.id,
                                                   joinable_type: joinable_type,
                                                   type: type,
                                                   user_id: user.id})
  end

  def default_message(joinable_type:, name:)
    object_name = (joinable_type=="Tour" ? "maraude" : "entourage")
    object_title = " : #{name}" if name.present?
    "Un nouveau membre souhaite rejoindre votre #{object_name}#{object_title}"
  end
end
class NewJoinRequestNotifyJob < ActiveJob::Base
  def perform(joinable_type, joinable_id, user_id, type, message)
    user = User.find(user_id)
    joinable = joinable_type.constantize.find(joinable_id)
    recipients = joinable.members.includes(:join_requests).where(join_requests: {status: "accepted"})
    push_message = message || "Un nouveau membre souhaite rejoindre votre maraude"
    PushNotificationService.new.send_notification(UserPresenter.new(user: user).display_name,
                                                  "Demande en attente",
                                                  push_message,
                                                  recipients,
                                                  {joinable_id: joinable.id,
                                                   joinable_type: joinable_type,
                                                   type: type,
                                                   user_id: user.id})
  end
end
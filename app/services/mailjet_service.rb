module MailjetService
  def self.handle_event payload
    return unless email = payload['email']
    return unless event = payload['event']
    return unless event == 'unsub'

    handle_unsub(email)
  end

  private

  def self.handle_unsub email
    User.where(email: email).each do |user|
      EmailPreferencesService.update_subscription(user: user, subscribed: false, category: :all)
    end
  end
end

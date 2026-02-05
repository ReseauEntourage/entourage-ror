module MailjetService
  def self.handle_event payload
    email = payload['email']
    event = payload['event']

    return unless email.present? && email.include?("@")
    return unless event.present? && event == 'unsub'

    handle_unsub(email)
  end

  private

  def self.handle_unsub email
    User.where(email: email).each do |user|
      EmailPreferencesService.update_subscription(user: user, subscribed: false, category: :all)
    end
  end
end

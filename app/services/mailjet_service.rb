module MailjetService
  def self.handle_event payload
    email = payload['email']
    event = payload['event']

    return unless email.present? && email.include?("@")
    return unless event.present? && event == 'unsub'

    category = JSON.parse(payload['Payload'])['unsubscribe_category'] rescue :default

    handle_unsub(email, category)
  end

  private

  def self.handle_unsub email, category
    User.where(email: email).each do |user|
      EmailPreferencesService.update_subscription(user: user, subscribed: false, category: category)
    end
  end
end

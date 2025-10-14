module MailjetService
  def self.handle_event payload
    case payload['event']
    when 'unsub'
      handle_unsub payload
    else
      e = RuntimeError.new("Unhandled Mailjet event #{payload['event'].inspect}")
      Sentry.capture_exception(e)
    end
  end

  private

  def self.handle_unsub payload
    return unless payload['event'] == 'unsub'
    category = JSON.parse(payload['Payload'])['unsubscribe_category'] rescue nil
    category ||= :default
    User.where(email: payload['email']).each do |user|
      EmailPreferencesService.update_subscription(
        user: user, subscribed: false, category: category)
    end
  end
end

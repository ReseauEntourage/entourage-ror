module MailjetService
  def self.handle_event payload
    case payload['event']
    when 'unsub'
      handle_unsub payload
    else
      e = RuntimeError.new("Unhandled Mailjet event #{payload['event'].inspect}")
      Raven.capture_exception(e)
    end
  end

  private

  def self.handle_unsub payload
    return unless payload['event'] == 'unsub'
    User.where(email: payload['email']).each do |user|
      user.update(accepts_emails: false)
    end
  end
end

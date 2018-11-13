module MailerErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from Net::ProtocolError, with: :handle_delivery_error
  end

  private

  def handle_delivery_error exception
    case exception.message.chomp
    when '401 4.1.3 Bad recipient address syntax',
         '501 5.1.3 Bad recipient address syntax'
      # Do nothing for now
      # TODO: handle badly formatted email addresses
    else
      # This will let Sidekiq retry the later in case of an async job
      raise exception
    end
  end
end

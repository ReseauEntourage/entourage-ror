# Handle exceptions raised on the delivery of emails
# (both synchronous and asynchronous).
#
# Inspired by the implementation found in Rails 5.2.1.rc1

if Rails.version > '4.2.x'
  raise "This patch was done for Rails 4.2. " \
        "There might be a better solution in #{Rails.version}."
end

module ActionMailer
  class Base < AbstractController::Base
    include ActiveSupport::Rescuable

    def handle_exceptions
      yield
    rescue => exception
      rescue_with_handler(exception) || raise
    end
  end

  class MessageDelivery < Delegator
    def __getobj__
      @mail_message ||= processed_mailer.message
    end

    def deliver_now!
      processed_mailer.handle_exceptions do
        message.deliver!
      end
    end

    def deliver_now
      processed_mailer.handle_exceptions do
        message.deliver
      end
    end

    private

    def processed_mailer
      @processed_mailer ||= @mailer.send(:new, @mail_method, *@args)
    end
  end
end

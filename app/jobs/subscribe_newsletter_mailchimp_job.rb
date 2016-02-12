class SubscribeNewsletterMailchimpJob < ActiveJob::Base

  def perform(email, active)
    if ENV.key?("MAILCHIMP_LIST_ID")
      begin
        mc = Mailchimp::API.new(ENV['MAILCHIMP_API_KEY'])
        if (active)
          begin
            mc.lists.subscribe(ENV['MAILCHIMP_LIST_ID'],{ "email" => email})
          rescue
            logger.error "Newsletter Subscription for #{email} could not be updated in Mailchimp !"
          end
        else
          begin
            mc.lists.unsubscribe(ENV['MAILCHIMP_LIST_ID'],{ "email" => email})
          rescue
            logger.error "Newsletter UNSubscription for #{email} could not be updated in Mailchimp !"
          end
        end
      end
    else
      logger.error "NewsletterSubscription isnot linked to Mailchimp !"
    end
  end

end
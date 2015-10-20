require 'mailchimp'

class NewsletterSubscription < ActiveRecord::Base

  validates :email, :active, presence: true
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, on: :create }
  validates :email, uniqueness: true
  scope :activeSuscribers, -> { where(active: true) }

  after_update :send_mailchimp_info
  after_create :send_mailchimp_info

  def send_mailchimp_info
    if ENV.key? "MAILCHIMP-LIST-ID"
      begin
        mc = Mailchimp::API.new(ENV['MAILCHIMP-API-KEY'])
        if (self.active)
          begin
            mc.lists.subscribe(ENV['MAILCHIMP-LIST-ID'],{ "email" => self.email})
            #mc.lists.subscribe(ENV['MAILCHIMP-LIST-ID'],{ "email" => self.email}, nil, 'html', true, true, true, true)
          rescue
            logger.error "Newsletter Subscription for #{email} could not be updated in Mailchimp !"
          end
        else
          begin
            mc.lists.unsubscribe(ENV['MAILCHIMP-LIST-ID'],{ "email" => self.email})
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

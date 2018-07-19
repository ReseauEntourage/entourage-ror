module EmailDeliveryHooks
  #
  # To include in the mailers that use these hooks
  #
  module Concern
    extend ActiveSupport::Concern

    included do
      register_interceptor EmailDeliveryHooks
      register_observer    EmailDeliveryHooks
    end

    def track_delivery user_id:, campaign:, deliver_only_once: false
      headers(
        TRACKING_HEADER => EmailDeliveryHooks.serialize(
          user_id: user_id,
          campaign: campaign
        ),
        ONLY_ONCE_HEADER => deliver_only_once
      )
    end

    def collect_samples rate:, address:
      headers(
        SAMPLING_HEADER => EmailDeliveryHooks.serialize(
          rate: rate,
          address: address
        )
      )
    end
  end

  #
  # Before delivery
  #
  def self.delivering_email(message)
    sample_emails(message) if sampling_required?(message)
    drop_duplicates(message) if deliver_only_once?(message)

    # delete the header that are not needed anymore
    [SAMPLING_HEADER, ONLY_ONCE_HEADER].each do |h|
      message[h] = nil
    end
  rescue => e
    handle_exception(e, message)
  end

  # Sampling:
  # for a subset of the recipients,
  # send a copy of every email sent to these users
  # to a secondary address for debugging
  SAMPLING_HEADER = 'X-Entourage-Sampling'

  def self.sample_emails(message)
    options = parse(message[SAMPLING_HEADER].value)
    if Array(message.to).any? { |email| sample(rate: options[:rate],
                                               key: email.downcase) }
      message.bcc = [*message.bcc, options[:address]].uniq
    end
  end

  def self.sampling_required?(message)
    message[SAMPLING_HEADER].present?
  end

  def self.sample(rate:, key:)
    hash = Digest::MD5.digest(key)
    first_16_bits = hash.unpack('S').first
    sample_upper_bound = 2**16 * rate
    first_16_bits < sample_upper_bound
  end

  # Only-once delivery :
  # make sure that certain emails are never sent more than once to
  # an user. This requires Delivery tracking (see below)
  TRACKING_HEADER  = 'X-Entourage-Track'
  ONLY_ONCE_HEADER = 'X-Entourage-Only-Once'

  def self.drop_duplicates(message)
    attributes = message[TRACKING_HEADER].try(:value)
    raise "Tracking header required to drop duplicates" if attributes.nil?

    if EmailDelivery.exists?(parse(attributes))
      message.perform_deliveries = false
    end
  end

  def self.deliver_only_once?(message)
    message[ONLY_ONCE_HEADER].try(:value) == 'true'
  end

  #
  # After delivery
  #
  def self.delivered_email(message)
    track_delivery(message) if tracking_required?(message)
  rescue => e
    handle_exception(e, message)
  end

  # Delivery tracking:
  # for some campaigns, keep a record in the database that
  # a given user has been sent the message
  def self.track_delivery(message)
    EmailDelivery.create!(parse(message[TRACKING_HEADER].value))
  end

  def self.tracking_required?(message)
    message[TRACKING_HEADER].present?
  end


  def self.handle_exception e, message
    if Rails.env.production?
      header = Hash[message.header.map { |a| [a.name, a.value] }] rescue $!
      Raven.capture_exception(e, extra: { header: header })
    else
      raise e
    end
  end

  def self.serialize(value)
    JSON.fast_generate(value)
  end

  def self.parse(value)
    JSON.parse(value).symbolize_keys
  end
end

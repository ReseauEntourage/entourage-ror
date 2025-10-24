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

    def set_delivery_hook_data data={}
      existing = @_message.instance_variable_get(:@delivery_hooks_data) || {}
      updated = existing.merge(data)
      @_message.instance_variable_set(:@delivery_hooks_data, updated)
    end

    def track_delivery user_id:, campaign: nil, deliver_only_once: false, detailed: :auto
      detailed = deliver_only_once if detailed == :auto

      if deliver_only_once && campaign.blank?
        raise '`deliver_only_once` requires campaign to be present'
      end

      if deliver_only_once && !detailed
        raise '`deliver_only_once` can not be used without `detailed` tracking'
      end

      set_delivery_hook_data(
        tracking: {
          user_id: user_id,
          campaign: campaign,
          detailed: detailed
        },
        deliver_only_once: deliver_only_once
      )
    end

    def collect_samples rate:, address:
      set_delivery_hook_data(
        sampling: {
          rate: rate,
          address: address
        }
      )
    end
  end

  #
  # Before delivery
  #
  def self.delivering_email(message)
    sample_emails(message) if sampling_required?(message)
    drop_duplicates(message) if deliver_only_once?(message)
  rescue => e
    handle_exception(e, message)
  end

  # Sampling:
  # for a subset of the recipients,
  # send a copy of every email sent to these users
  # to a secondary address for debugging

  def self.sample_emails(message)
    options = data(message)[:sampling]
    if Array(message.to).any? { |email| sample(rate: options[:rate],
                                               key: email.downcase) }
      message.bcc = [*message.bcc, options[:address]].uniq
    end
  end

  def self.sampling_required?(message)
    data(message).key?(:sampling)
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

  def self.drop_duplicates(message)
    attributes = data(message)[:tracking]&.slice(:user_id, :campaign)
    raise 'Tracking header required to drop duplicates' if attributes.nil?

    if EmailDelivery.for_campaign(attributes[:campaign])
                    .exists?(user_id: attributes[:user_id])
      message.perform_deliveries = false
      Rails.logger.debug "type=email_delivery_hook.dropped_duplicate campaign=#{attributes[:campaign]} user_id=#{attributes[:user_id]}"
    end
  end

  def self.deliver_only_once?(message)
    data(message)[:deliver_only_once] == true
  end

  #
  # After delivery
  #
  def self.delivered_email(message)
    return unless message.perform_deliveries
    if !Rails.env.production?
      Rails.logger.debug "type=email_delivery.delivery_method method=#{ActionMailer::Base.delivery_methods.invert[message.delivery_method.class]} campaign=#{data(message).dig(:tracking, :campaign)} user_id=#{data(message).dig(:tracking, :user_id)}"
    end
    track_delivery_timestamp(message)
    track_detailed_delivery(message) if detailed_tracking_required?(message)
  rescue => e
    handle_exception(e, message)
  end

  # Delivery tracking

  # update users.last_email_sent_at
  def self.track_delivery_timestamp(message)
    user_id = data(message).dig(:tracking, :user_id)
    if user_id
      User.where(id: user_id).update_all([
        'last_email_sent_at = greatest(last_email_sent_at, ?)',
        Time.now
      ])
    end
  end

  # for some campaigns, keep a record in the database that
  # a given user has been sent the message
  def self.detailed_tracking_required?(message)
    data(message).dig(:tracking, :detailed) == true
  end

  def self.track_detailed_delivery(message)
    tracking = data(message)[:tracking]
    campaign = EmailCampaign.find_or_create_by!(name: tracking[:campaign])
    campaign.deliveries.create!(user_id: tracking[:user_id])
  end


  def self.handle_exception e, message
    if Rails.env.production?
      header = Hash[message.header.map { |a| [a.name, a.value] }] rescue $!

      Rails.logger.error(e)
    else
      raise e
    end
  end

  def self.serialize(value)
    JSON.fast_generate(value)
  end

  def self.data(message)
    message.instance_variable_get(:@delivery_hooks_data) || {}
  end
end

# frozen_string_literal: true

module MailchimpService
  BASE = "https://%{dc}.api.mailchimp.com/3.0"
  UPDATE_MEMBER = "/lists/%{list_id}/members/%{subscriber_hash}"

  def self.unsubscribe(list:, email:)
    update(list, email, {
      status: :unsubscribed
    })
  end

  def self.set_interest list:, email:, interest:, value:
    interest_id = list_config(list).dig('interests', interest.to_s)

    raise ConfigError, "ID of interest '#{list['name']}/#{interest}' not found in Mailchimp config" if interest_id.nil?
    raise ":value must be a boolean" unless value.in?([true, false])

    update(list, email, {
      interests: {
        interest_id => value
      }
    })
  end

  def self.list_config list_name
    list_name = list_name.to_s
    list = config.dig('lists', list_name) || {}

    raise ConfigError, "ID of list '#{list_name}' not found in Mailchimp config" if list['id'].nil?

    list
  end

  def self.config
    Rails.configuration.x.mailchimp
  end

  def self.add_or_update(list, email, body={})
    update_with_method(:put, list, email, body)
  end

  def self.update(list, email, body={})
    update_with_method(:patch, list, email, body)
  end

  def self.update_with_method(method, list, email, body={})
    list_id = list_config(list)['id']

    email = normalize_email(email)
    return if email.nil?

    return unless safety_mailer_whitelisted?(email)

    if method == :put
      body[:email_address] = email
    end

    subscriber_hash = Digest::MD5.hexdigest(email)

    path = UPDATE_MEMBER % {
      list_id: list_id,
      subscriber_hash: subscriber_hash
    }

    response = request(method, path, body)
  end

  def self.normalize_email email
    return if email.nil?
    email.to_s.strip.downcase.presence
  end

  def self.safety_mailer_whitelisted? email
    return true if ActionMailer::Base.delivery_method != :safety_mailer

    klass = ActionMailer::Base.delivery_methods[:safety_mailer]
    settings = ActionMailer::Base.safety_mailer_settings

    return true if klass.new(settings).whitelisted?(email)

    Rails.logger.warn("*** suppressed MailChimp operation for #{email}")
    return false
  end

  def self.request method, path, body
    raise ConfigError, "Mailchimp API key is not set" if config['api_key'].nil?

    dc = config['api_key'].split('-').last
    raise ConfigError, "Mailchimp API key is invalid" if dc.nil?

    url = File.join(BASE, path) % {dc: dc}

    response = HTTParty.send(
      method,
      url,
      basic_auth: {password: config['api_key']},
      headers: {'Content-Type' => 'application/json'},
      body: JSON.fast_generate(body),
    )

    unless response.success?
      exception = ApiError.for(response)
      Rails.logger.error exception.response
      raise exception
    end

    response.parsed_response
  end

  class ConfigError < ArgumentError
  end

  class ApiError < RuntimeError
    attr_reader :response, :code, :title, :detail

    def initialize response, payload: nil
      payload ||= JSON.parse(response.body) rescue {}
      @response = payload.presence || response.body
      @code = payload['status'] || response.code
      @title = payload['title'] || response.message
      @detail = payload['detail']
    end

    def message
      @message ||= begin
        message = "#{code} #{title}"
        message = "#{message}: #{detail}" if detail.present?
        message
      end
    end

    def self.for response
      payload = JSON.parse(response.body) rescue {}
      status = payload['status']
      title  = payload['title']
      klass =
        case [status, title]
        when [404, 'Resource Not Found']
          ResourceNotFound
        when [400, 'Forgotten Email Not Subscribed']
          ForgottenEmailNotSubscribed
        else
          ApiError
        end
      klass.new(response, payload: payload)
    end
  end

  class ResourceNotFound < ApiError; end
  class ForgottenEmailNotSubscribed < ApiError; end
end

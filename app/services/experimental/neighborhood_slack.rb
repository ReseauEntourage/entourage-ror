module Experimental::NeighborhoodSlack
  extend self

  def notify neighborhood_id
    record = Neighborhood.find_by_id(neighborhood_id)
    return unless record

    webhook_url = webhook_url_for(record)
    return if webhook_url.blank?

    payload_json = payload(record).to_json

    uri = URI(webhook_url)
    response = Net::HTTP.post(uri, payload_json, 'Content-Type' => 'application/json')

    Rails.logger.info("[SlackNotifier] POST #{uri} => #{response.code} #{response.body}")
  rescue => e
    Rails.logger.error("[SlackNotifier] Error: #{e.class} #{e.message}")
  end

  def webhook_url_for record
    return if ENV['SLACK_APP_WEBHOOKS'].blank?

    config = JSON.parse(ENV['SLACK_APP_WEBHOOKS']) rescue nil
    return if config.nil?

    channel = record.postal_code&.first(2).presence && config[record.postal_code.first(2)]
    channel ||= config['default']
    return if channel.blank?

    [config['prefix'], channel].join
  end

  def payload record
    {
      blocks: [
        {
          type: 'header',
          text: {
            type: 'plain_text',
            text: record.title,
            emoji: true
          }
        },
        {
          type: 'context',
          elements: [
            {
              type: 'image',
              image_url: UserServices::Avatar.new(user: record.user).thumbnail_url(expire: 7.days),
              alt_text: 'avatar'
            },
            {
              type: 'mrkdwn',
              text: "*#{subtitle(record)}*"
            }
          ]
        },
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: "*#{text(record)}*\n\n#{record.description}"
          },
          accessory: record.image_url.present? ? {
            type: 'image',
            image_url: record.image_url,
            alt_text: 'illustration'
          } : nil
        }.compact,
        {
          type: 'actions',
          elements: [
            {
              type: 'button',
              text: { type: 'plain_text', text: '✅ Valider' },
              style: 'primary',
              action_id: 'validate',
              value: "neighborhood_validation:#{record.id.to_s}"
            },
            {
              type: 'button',
              text: { type: 'plain_text', text: '🚫 Bloquer' },
              style: 'danger',
              action_id: 'block',
              value: "neighborhood_validation:#{record.id.to_s}",
              confirm: {
                title: { type: 'plain_text', text: 'Masquer cette action ?' },
                text: { type: 'mrkdwn', text: "Elle n'apparaîtra plus dans les recherches." },
                confirm: { type: 'plain_text', text: 'Oui' },
                deny: { type: 'plain_text', text: 'Non' }
              }
            },
            {
              type: 'button',
              text: { type: 'plain_text', text: '👀 Afficher' },
              url: links_url(record)
            }
          ]
        }
      ]
    }
  end

  def text record
    "Groupe de voisins par _#{UserPresenter.new(user: record.user).display_name}_"
  end

  def subtitle record
    interests = record.interests.map(&:name).join(', ')
    "#{record.title} (#{interests}) • #{record.postal_code}"
  end

  def h
    @h ||= Class.new do
      include Rails.application.routes.url_helpers
    end.new
  end

  def links_url record
    h.admin_slack_neighborhood_links_url(record, host: ENV['ADMIN_HOST'])
  end

  module Callback
    extend ActiveSupport::Concern

    included do
      after_create :notify_slack
    end

    private

    def notify_slack
      AsyncService.new(Experimental::NeighborhoodSlack).notify(id)
    end
  end
end

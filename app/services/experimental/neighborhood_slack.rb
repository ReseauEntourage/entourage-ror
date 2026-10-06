module Experimental::NeighborhoodSlack
  def self.notify neighborhood_id
    return unless record = Neighborhood.find_by_id(neighborhood_id)

    notifier(record)&.ping(payload(record))
  end

  def self.notifier record
    return unless url = ModerationServices.slack_app_webhook_url(record)

    Slack::Notifier.new(url)
  end

  def self.payload record
    {
      attachments: [
        {
          color: '#3AA3E3',
          author_name: subtitle(record),
          thumb_url: UserServices::Avatar.new(user: record.user).thumbnail_url(expire: 7.days),
          title: record.title,
          text: text(record),
          mrkdwn_in: [:text]
        },
        {
          text: record.description,
          thumb_url: record.image_url,
        },
        {
          callback_id: [:neighborhood_validation, record.id].join(':'),
          fallback: '',
          actions: [
            {
              text:  'Valider',
              type:  :button,
              style: :primary,
              name:  :action,
              value: :validate
            },
            {
              text:  'Bloquer',
              type:  :button,
              style: :danger,
              name:  :action,
              value: :block,
              confirm: {
                title:        'Masquer cette action ?',
                text:         "Elle n'apparaîtra plus dans les recherches.",
                ok_text:      'Oui',
                dismiss_text: 'Non'
              }
            },
            {
              text:  'Afficher',
              type:  :button,
              url: links_url(record)
            }
          ]
        }
      ].compact
    }
  end

  def self.text record
    "Groupe de voisins par _#{UserPresenter.new(user: record.user).display_name}_"
  end

  def self.subtitle record
    "#{record.title} (#{record.interests.map(&:name).join(', ')}) • #{record.postal_code}"
  end

  def self.h
    @h ||= Class.new do
      include Rails.application.routes.url_helpers
    end.new
  end

  def self.links_url record
    h.admin_slack_neighborhood_links_url(record, host: ENV['ADMIN_HOST'])
  end

  module Callback
    extend ActiveSupport::Concern

    included do
      after_create :auto_validate
      after_create :notify_slack
    end

    private

    def auto_validate
      return unless user.team? || user.ambassador?

      update_attribute(:status, :active)
    end

    def notify_slack
      return if user.team? || user.ambassador?

      AsyncService.new(Experimental::NeighborhoodSlack).notify(id)
    end
  end
end

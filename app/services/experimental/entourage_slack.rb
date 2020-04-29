module Experimental::EntourageSlack
  def self.notify entourage
    notifier(entourage)&.ping(payload(entourage))
  end

  def self.notifier entourage
    return if ENV['SLACK_APP_WEBHOOKS'].blank?
    config = JSON.parse(ENV['SLACK_APP_WEBHOOKS']) rescue nil
    return if config.nil?
    channel = nil
    if entourage.country == 'FR' && entourage.postal_code.present?
      channel = config[entourage.postal_code.first(2)]
    end
    channel ||= config['default']
    url = config['prefix'] + channel
    Slack::Notifier.new(url)
  end

  def self.payload entourage
    e = entourage
    {
      text: "Nouvelle action",
      attachments: [
        {
          color: "#3AA3E3",
          author_icon: asset_url(e.user.avatar_key.present? ? h.entourage_category_image_path(e) : "user/default_avatar.png"),
          author_name: "#{h.entourage_type_phrase(e)} › #{h.entourage_category_phrase(e)} • #{e.approximated_location}",
          thumb_url: UserServices::Avatar.new(user: entourage.user).thumbnail_url(expire: 7.days),
          title: entourage.title,
          text: "#{h.entourage_type_name(e)} par _#{UserPresenter.new(user: e.user).display_name}_",
          mrkdwn_in: [:text]
        },
        ({
          text: e.description,
        } if e.description.present?),
        ({
          color: :danger,
          title: "Consentement non obtenu",
          text: "Cette action est suspendue (invisible dans le feed) en attendant la confirmation du consentement.",
        } if e.status == 'suspended'),
        {
          callback_id: [:entourage_validation, e.id].join(':'),
          fallback: "",
          actions: [
            {
              text:  "Valider",
              type:  :button,
              style: :primary,
              name:  :action,
              value: :validate
            },
            {
              text:  "Bloquer",
              type:  :button,
              style: :danger,
              name:  :action,
              value: :block,
              confirm: {
                title:        "Masquer cette action ?",
                text:         "Elle n'apparaîtra plus dans le feed.",
                ok_text:      "Oui",
                dismiss_text: "Non"
              }
            },
            {
              text:  "Afficher",
              type:  :button,
              url: h.admin_slack_entourage_links_url(e, host: ENV['ADMIN_HOST'])
            }
          ]
        }
      ].compact
    }
  end

  def self.h
    @h ||= Class.new do
      include EntouragesHelper
      include Rails.application.routes.url_helpers
    end.new
  end

  def self.asset_url path
    File.join(h.root_url, "/assets/", path)
  end

  def self.enable_callback
    !Rails.env.test?
  end

  module Callback
    extend ActiveSupport::Concern

    included do
      after_commit :notify_slack, on: :create
    end

    private

    def notify_slack
      return unless Experimental::EntourageSlack.enable_callback
      return unless community == 'entourage' && group_type == 'action'
      AsyncService.new(Experimental::EntourageSlack).notify(self)
    end
  end
end

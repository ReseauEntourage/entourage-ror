module Experimental::EntourageSlack
  def self.notify entourage
    notifier(entourage)&.ping(payload(entourage))
  end

  def self.notifier entourage
    # New webhooks can be created at
    # https://api.slack.com/apps/AAJQG6LDP/general
    # > Install your app to your workspace
    #
    # Existing webhooks are listed here
    # https://api.slack.com/apps/AAJQG6LDP/install-on-team
    #
    # They can be revoked here
    # https://my.slack.com/apps/AAJQG6LDP

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
    slack_moderator = ModerationServices.slack_moderator_id(entourage.user)

    e = entourage
    subtitle =
      case e.group_type
      when 'action'
        "#{h.entourage_type_phrase(e)} › #{h.entourage_category_phrase(e)} • #{e.metadata[:display_address]}"
      when 'outing'
        address_fragments = e.metadata[:street_address].split(', ')
        address_fragments.pop if address_fragments.last == 'France'
        maybe_city = address_fragments.last
        subtitle_place =
          if maybe_city
            maybe_city.gsub!(/^#{e.postal_code} /, '')
            "#{maybe_city} (#{e.postal_code})"
          else
            e.postal_code
          end
        "Évènement • #{subtitle_place} (<@#{slack_moderator}>)"
      end

    text =
      case e.group_type
      when 'action'
        "#{h.entourage_type_name(e)} par _#{UserPresenter.new(user: e.user).display_name}_ (<@#{slack_moderator}>)"
      when 'outing'
        "par _#{UserPresenter.new(user: e.user).display_name}_ (<@#{slack_moderator}>)"
      end

    event_metadata =
      if e.group_type == 'outing'
        url = "https://www.google.com/maps/search/?api=1&" + {
          query: e.metadata[:display_address],
          query_place_id: e.metadata[:google_place_id]
        }.to_query

        event_metadata_text = [
          "📅 #{e.metadata_datetimes_formatted}",
          "📍 <#{url}|#{e.metadata[:display_address]}>"
        ].join("\n")

        {text: event_metadata_text}
      end

    {
      attachments: [
        {
          color: "#3AA3E3",
          author_icon: UserServices::Avatar.new(user: entourage.user).thumbnail_url(expire: 7.days),
          author_name: subtitle,
          thumb_url: e.image_path,
          title: entourage.title,
          text: text,
          mrkdwn_in: [:text]
        },
        event_metadata,
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
                text:         "Elle n'apparaîtra plus dans les recherches.",
                ok_text:      "Oui",
                dismiss_text: "Non"
              }
            },
            {
              text:  "Afficher",
              type:  :button,
              url: links_url(e)
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

  def self.links_url entourage
    h.admin_slack_entourage_links_url(entourage, host: ENV['ADMIN_HOST'])
  end

  def self.enable_callback
    !Rails.env.test?
  end

  module Callback
    extend ActiveSupport::Concern

    included do
      after_commit :notify_slack
    end

    private

    def departement_changed?
      return false unless previous_changes.key?('postal_code')
      previous_changes['postal_code'].map { |pc| pc.to_s.first(2) }.uniq.many?
    end

    def notify_slack
      return unless Experimental::EntourageSlack.enable_callback
      return unless community == 'entourage' && group_type.in?(['action', 'outing'])
      return unless [country, postal_code].all?(&:present?)
      return unless previous_changes.key?('country') || departement_changed?
      AsyncService.new(Experimental::EntourageSlack).notify(self)
    end
  end
end

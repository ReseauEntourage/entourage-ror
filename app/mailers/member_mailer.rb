class MemberMailer < MailjetMailer
  default from: "contact@entourage.social"

  def welcome(user)
    community = user.community
    mailjet_email to: user,
                  template_id: community.mailjet_template['welcome'],
                  campaign_name: community_prefix(community, :welcome),
                  from: email_with_name("contact@entourage.social", "Le Réseau Entourage"),
                  variables: {
                    outings_url: Entourage.share_url(:outings),
                    outings: Outing.future_or_ongoing.welcome_category.limit(3).map { |outing|
                      {
                        name: outing.title,
                        address: outing.event_url,
                        date: I18n.l(outing.metadata[:starts_at].to_date, format: :short, locale: user.lang),
                        hour: outing.metadata[:starts_at].strftime("%Hh%M"),
                        image_url: outing.image_url_with_size(:landscape_url, :medium),
                        url: outing.share_url
                      }
                    }
                  }
  end

  def incomplete_profile(user)
    mailjet_email to: user,
                  template_id: 6174246,
                  campaign_name: 'onboarding_incomplete_profile'
  end

  def onboarding_day_8(user)
    mailjet_email to: user,
                  template_id: 452755,
                  campaign_name: 'onboarding_j_8'
  end

  def onboarding_day_14(user)
    mailjet_email to: user,
                  template_id: 456172,
                  campaign_name: 'onboarding_j_14'
  end

  def reactivation_day_20(user)
    mailjet_email to: user,
                  template_id: 456175,
                  campaign_name: 'relance_j_20',
                  deliver_only_once: true
  end

  def action_follow_up_day_15(action)
    mailjet_email to: action.user,
                  template_id: 452754,
                  campaign_name: 'action_suivi_j_10',
                  variables: {
                    action => [
                      :entourage_title,
                      :entourage_url,
                      :entourage_share_url,
                    ]
                  }
  end

  def weekly_planning user, action_ids, outing_ids
    return unless outing_ids.any? || action_ids.any?

    template_id = user.ask_for_help? ? 5995407 : 5935421
    user_profile = user.is_ask_for_help? ? :ask_for_help : :offer_help

    actions = Action.where(id: action_ids).limit(3)
    outings = Outing.where(id: outing_ids).limit(3)

    action_url = Entourage.share_url(user.is_ask_for_help? ? :contributions : :solicitations)
    outing_url = Entourage.share_url(:outings)

    moderator = ModerationServices.moderator_for_user(user)

    mailjet_email to: user,
                  template_id: template_id,
                  campaign_name: 'planning_hebdo',
                  variables: {
                    user_profile: user_profile,
                    action_count: actions.count,
                    actions_url: action_url,
                    actions: actions.map { |action|
                      {
                        name: action.title,
                        address: action.metadata[:city],
                        description: action.description,
                        image_url: action.image_url_with_size(:image_url, :medium),
                        url: action.share_url
                      }
                    },
                    outing_count: outings.count,
                    outings_url: outing_url,
                    outings: outings.map { |outing|
                      {
                        name: outing.title,
                        address: outing.online? ? outing.event_url : outing.metadata[:display_address],
                        date: I18n.l(outing.metadata[:starts_at].to_date, format: :short, locale: user.lang),
                        hour: outing.metadata[:starts_at].strftime("%Hh%M"),
                        image_url: outing.image_url_with_size(:landscape_url, :medium),
                        url: outing.share_url
                      }
                    },
                    moderator: {
                      name: moderator.first_name,
                      email: moderator.email,
                      phone: moderator.phone,
                      image_url: UserServices::Avatar.new(user: moderator).thumbnail_url,
                    }
                  }
  end

  def poi_report(poi, user, message)
    if ENV.key? "POI_REPORT_EMAIL"
      @poi = poi
      @user = user
      @message = message

      mail(to: ENV["POI_REPORT_EMAIL"], subject: 'Correction de POI')
    else
      logger.warn "Could not deliver POI report. Please provide POI_REPORT_EMAIL as an environment variable"
    end
  end

  def user_export user_id:, recipient:, cci:
    attachments["user-export.csv"] = File.read(
      UserServices::Exporter.new(user: User.find(user_id)).csv
    )

    mail(
      to: recipient,
      bcc: cci,
      subject: "Export des données personnelles d'Entourage"
    )
  end

  def users_csv_export user_ids, recipient
    attachments["users-csv-export.csv"] = File.read(
      UserServices::ListExporter.export(user_ids)
    )

    mail(
      to: recipient,
      subject: "Export des utilisateurs"
    )
  end

  def entourages_csv_export entourage_ids, recipient
    attachments["entourages-csv-export.csv"] = File.read(
      EntourageServices::ListExporter.export(entourage_ids)
    )

    mail(
      to: recipient,
      subject: "Export des actions et événements"
    )
  end

  def pois_csv_export poi_ids, recipient
    attachments["pois-csv-export.csv"] = File.read(
      PoiServices::ListExporter.export(poi_ids)
    )

    mail(
      to: recipient,
      subject: "Export des pois"
    )
  end

  def poi_import csv:, recipient:
    PoiServices::Importer.read(csv: CSV.parse(csv, headers: true)) do |successes, errors|
      @successes = successes
      @errors = errors

      mail to: recipient, subject: "Import de POI"
    end
  end
end

class MemberMailer < MailjetMailer
  default from: 'contact@entourage.social'

  def welcome(user)
    community = user.community
    mailjet_email to: user,
                  template_id: community.mailjet_template['welcome'],
                  campaign_name: community_prefix(community, :welcome),
                  from: email_with_name('contact@entourage.social', 'Le Réseau Entourage'),
                  variables: {
                    outings_url: Entourage.share_url(:outings),
                    outings: Outing.future_or_ongoing.welcome_category.limit(3).map { |outing|
                      {
                        name: outing.title,
                        address: outing.event_url,
                        date: I18n.l(outing.metadata[:starts_at].to_date, format: :short, locale: user.lang),
                        hour: outing.metadata[:starts_at].strftime('%Hh%M'),
                        image_url: outing.image_url_with_size(:landscape_url, :medium),
                        url: outing.share_url
                      }
                    }
                  }
  end

  def congratulations_new_badge(user, badge_tag, awarded_at)
    data = UserBadge.display_data_for(badge_tag, locale: user.lang)

    return unless data

    mailjet_email to: user,
                  template_id: 8099538,
                  campaign_name: 'badge_congratulations',
                  variables: {
                    badge_image_url: UserBadge.image_url_for(badge_tag),
                    badge_nom: data[:nom],
                    badge_description: data[:description],
                    badge_date: I18n.l(awarded_at.to_date, format: :long, locale: user.lang),
                    badges: UserBadge.share_url,
                    deeplink_badges: UserBadge.share_url,
                  }
  end

  def first_steps_invitation(user)
    outings = Outing.first_steps_category.future_or_ongoing.default_order.limit(3)

    return unless outings.any?

    mailjet_email to: user,
                  template_id: 7996265,
                  campaign_name: 'first_steps_invitation',
                  deliver_only_once: true,
                  variables: {
                    outings: outings.map { |outing|
                      {
                        name: outing.title,
                        date: I18n.l(outing.metadata[:starts_at].to_date, format: :short, locale: user.lang),
                        hour: outing.metadata[:starts_at].strftime('%Hh%M'),
                        url: outing.share_url,
                        women_only: outing.reserved_female == true
                      }
                    }
                  }
  end

  def papotages_invitation_j7(user)
    outings = Outing.papotages.future_or_ongoing.default_order.limit(3)

    return unless outings.any?

    mailjet_email to: user,
                  template_id: 8016225,
                  campaign_name: 'papotages_invitation_j7',
                  deliver_only_once: true,
                  variables: {
                    outings: outings.map { |outing|
                      {
                        name: outing.title,
                        date: I18n.l(outing.metadata[:starts_at].to_date, format: :short, locale: user.lang),
                        hour: outing.metadata[:starts_at].strftime('%Hh%M'),
                        url: outing.share_url,
                        women_only: outing.reserved_female == true
                      }
                    }
                  }
  end

  def incomplete_profile(user)
    mailjet_email to: user,
                  template_id: 6174246,
                  campaign_name: 'onboarding_incomplete_profile'
  end

  def first_steps_papotages_invitation(user, papotages)
    return unless papotages.any?

    mailjet_email to: user,
                  template_id: 8019081,
                  campaign_name: 'first_steps_papotages_invitation',
                  deliver_only_once: true,
                  variables: {
                    outings_url: Entourage.share_url(:outings),
                    outings: papotages.map { |papotage|
                      {
                        name: papotage.title,
                        date: I18n.l(papotage.metadata[:starts_at].to_date, format: :short, locale: user.lang),
                        hour: papotage.metadata[:starts_at].strftime('%Hh%M'),
                        image_url: papotage.image_url_with_size(:landscape_url, :medium),
                        url: papotage.share_url
                      }
                    }
                  }
  end

  def onboarding_day_8(user)
    mailjet_email to: user,
                  template_id: 452755,
                  campaign_name: 'onboarding_j_8'
  end

  def unseen_video_day_5(user)
    welcome_video = Resource.find_by(tag: :welcome)
    return unless welcome_video

    mailjet_email to: user,
                  template_id: 7995949,
                  campaign_name: 'relance_video_j_5',
                  deliver_only_once: true,
                  variables: {
                    video_url: welcome_video.share_url
                  }
  end

  def action_follow_up_day_15(action)
    mailjet_email to: action.user,
                  template_id: 452754,
                  campaign_name: 'action_suivi_j_10',
                  variables: {
                    entourage_title: action.title,
                    entourage_share_url: action.share_url,
                    action: {
                      title: action.title,
                      url: action.share_url
                    }
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
                        hour: outing.metadata[:starts_at].strftime('%Hh%M'),
                        image_url: outing.image_url_with_size(:landscape_url, :medium),
                        url: outing.share_url,
                        reserved_female: outing.reserved_female
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
    if ENV.key? 'POI_REPORT_EMAIL'
      @poi = poi
      @user = user
      @message = message

      mail(to: ENV['POI_REPORT_EMAIL'], subject: 'Correction de POI')
    else
      logger.warn 'Could not deliver POI report. Please provide POI_REPORT_EMAIL as an environment variable'
    end
  end

  def user_export user_id:, recipient:, cci:
    attachments['user-export.csv'] = File.read(
      UserServices::Exporter.new(user: User.find(user_id)).csv
    )

    mail(
      to: recipient,
      bcc: cci,
      subject: "Export des données personnelles d'Entourage"
    )
  end

  def users_csv_export user_ids, recipient
    attachments['users-csv-export.csv'] = File.read(
      UserServices::ListExporter.export(user_ids)
    )

    mail(
      to: recipient,
      subject: 'Export des utilisateurs'
    )
  end

  def entourages_csv_export entourage_ids, recipient
    attachments['entourages-csv-export.csv'] = File.read(
      EntourageServices::ListExporter.export(entourage_ids)
    )

    mail(
      to: recipient,
      subject: 'Export des actions et événements'
    )
  end

  def pois_csv_export poi_ids, recipient
    attachments['pois-csv-export.csv'] = File.read(
      PoiServices::ListExporter.export(poi_ids)
    )

    mail(
      to: recipient,
      subject: 'Export des pois'
    )
  end

  def poi_import csv:, recipient:
    PoiServices::Importer.read(csv: CSV.parse(csv, headers: true)) do |successes, errors|
      @successes = successes
      @errors = errors

      mail to: recipient, subject: 'Import de POI'
    end
  end
end

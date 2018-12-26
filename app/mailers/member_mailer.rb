class MemberMailer < MailjetMailer
  default from: "contact@entourage.social"
  add_template_helper(OrganizationHelper)

  COMMUNITY_EMAIL   = ENV["COMMUNITY_EMAIL"]   || "communaute@entourage.social"
  TOUR_REPORT_EMAIL = ENV["TOUR_REPORT_EMAIL"] || "maraudes@entourage.social"

  def welcome(user)
    community = user.community
    mailjet_email to: user,
                  template_id: community.mailjet_template['welcome'],
                  campaign_name: community_prefix(community, :welcome),
                  from: email_with_name("contact@entourage.social", "Le Réseau Entourage")
  end

  def onboarding_day_8(user)
    mailjet_email to: user,
                  template_id: 452755,
                  campaign_name: :onboarding_j_8
  end

  def onboarding_day_14(user)
    mailjet_email to: user,
                  template_id: 456172,
                  campaign_name: :onboarding_j_14
  end

  def reactivation_day_20(user)
    track_delivery user_id: user.id, campaign: :reactivation_day_20,
                   deliver_only_once: true
    mailjet_email to: user,
                  template_id: 456175,
                  campaign_name: :relance_j_20
  end

  def reactivation_day_40(user)
    track_delivery user_id: user.id, campaign: :reactivation_day_40,
                   deliver_only_once: true
    mailjet_email to: user,
                  template_id: 456194,
                  campaign_name: :relance_j_40
  end

  def action_follow_up_day_10(action)
    mailjet_email to: action.user,
                  template_id: 452754,
                  campaign_name: :action_suivi_j_10,
                  groups: {
                    action: action
                  }
  end

  def action_follow_up_day_20(action)
    action_url = "#{ENV['WEBSITE_URL']}/entourages/#{action.uuid_v2}"
    mailjet_email to: action.user,
                  template_id: 451123,
                  campaign_name: :action_suivi_j_20,
                  groups: {
                    action: action
                  },
                  variables: {
                    action_success_url: one_click_update_api_v1_entourage_url(
                      host: API_HOST,
                      protocol: :https,
                      id: action.uuid_v2,
                      signature: SignatureService.sign(action.id),
                    ),
                    action_support_url: "mailto:guillaume@entourage.social?" + {
                      subject: "Demande d'aide pour mon action [##{action.id}]",
                      body: "\n\n--\nLien vers l'action : #{action_url}"
                    }.to_query
                  }
  end

  def action_outcome_success(action)
    mailjet_email to: action.user,
                  template_id: 366621,
                  campaign_name: :action_aboutie,
                  variables: {
                    action_title: action.title,
                    action_author_type: action.moderation&.action_author_type,
                    action_type: action.moderation&.action_type&.split(':')&.first&.strip,
                    volunteering_form_url: redirect_api_v1_link_url(
                      host: API_HOST,
                      protocol: :https,
                      id: :volunteering,
                      token: action.user.token,
                    )
                  }
  end

  def tour_report(tour)
    @tour = tour
    @user = tour.user
    @tour_presenter = TourPresenter.new(tour: @tour)

    exporter = ExportServices::TourExporter.new(tour: tour)
    attachments['tour_points.csv'] = File.read(exporter.export_tour_points)
    attachments['encounters.csv'] = File.read(exporter.export_encounters)

    headers(
      'X-MJ-EventPayload' => JSON.fast_generate(
        type: :tour_report,
        tour_id: tour.id
      ),
      'X-Mailjet-Campaign' => :tour_report,
      'X-MJ-CustomID' => "tour_report-#{tour.id}"
    )

    mail(
      from: TOUR_REPORT_EMAIL,
      to: @user.email,
      cc: @user.organization.tour_report_cc,
      subject: 'Résumé de la maraude'
    ) if @user.email.present? || @user.organization.tour_report_cc.present?
  end

  def poi_report(poi, user, message)
    if ENV.key? "POI_REPORT_EMAIL"
      @poi = poi
      @user = user
      @message = message

      mail(to: ENV["POI_REPORT_EMAIL"], subject: 'Correction de POI')
    else
      logger.warn "Could not deliver POI report. Please provide POI_REPORT_EMAIL as an environment variable".red
    end
  end

  def registration_request_accepted(user)
    @user = user
    mail(from: COMMUNITY_EMAIL, to: @user.email, subject: "Votre demande d'adhésion à la plateforme Entourage a été acceptée") if @user.email.present?
  end
end

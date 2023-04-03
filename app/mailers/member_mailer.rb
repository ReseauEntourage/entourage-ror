class MemberMailer < MailjetMailer
  default from: "contact@entourage.social"
  add_template_helper(OrganizationHelper)

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

  def action_follow_up_day_10(action)
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

  def tour_report(tour)
    @tour = tour
    @user = tour.user
    @tour_presenter = TourPresenter.new(tour: @tour)

    exporter = ExportServices::TourExporter.new(tour: tour)
    attachments['tour_points.csv'] = File.read(exporter.export_tour_points)
    attachments['encounters.csv'] = File.read(exporter.export_encounters)

    headers(
      'X-MJ-EventPayload' => JSON.fast_generate(
        type: 'tour_report',
        tour_id: tour.id
      ),
      'X-Mailjet-Campaign' => 'tour_report',
      'X-MJ-CustomID' => "tour_report-#{tour.id}"
    )

    track_delivery(
      user_id: @user.id,
      campaign: 'tour_report',
      detailed: true
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

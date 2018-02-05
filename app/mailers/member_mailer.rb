class MemberMailer < ActionMailer::Base
  default from: "contact@entourage.social"
  add_template_helper(OrganizationHelper)

  COMMUNITY_EMAIL   = ENV["COMMUNITY_EMAIL"]   || "communaute@entourage.social"
  TOUR_REPORT_EMAIL = ENV["TOUR_REPORT_EMAIL"] || "maraudes@entourage.social"

  def welcome(user)
    @user = user

    headers['X-MJ-EventPayload'] = JSON.fast_generate(
      type: :welcome,
      user_id: user.id
    )

    mail(from: email_with_name("contact@entourage.social", "Claire d'Entourage"), to: user.email, subject: 'Bienvenue sur Entourage !') if user.email.present?
  end

  def tour_report(tour)
    @tour = tour
    @user = tour.user
    @tour_presenter = TourPresenter.new(tour: @tour)

    exporter = ExportServices::TourExporter.new(tour: tour)
    attachments['tour_points.csv'] = File.read(exporter.export_tour_points)
    attachments['encounters.csv'] = File.read(exporter.export_encounters)

    headers['X-MJ-EventPayload'] = JSON.fast_generate(
      type: :tour_report,
      tour_id: tour.id
    )

    mail(from: TOUR_REPORT_EMAIL, to: @user.email, subject: 'Résumé de la maraude') if @user.email.present?
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

  private

  def email_with_name(email, name)
    %("#{name}" <#{email}>)
  end
end

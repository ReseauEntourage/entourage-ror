class MemberMailer < ActionMailer::Base
  default from: "contact@entourage.social"
  add_template_helper(OrganizationHelper)

  rescue_from Net::ProtocolError, with: :handle_delivery_error

  COMMUNITY_EMAIL   = ENV["COMMUNITY_EMAIL"]   || "communaute@entourage.social"
  TOUR_REPORT_EMAIL = ENV["TOUR_REPORT_EMAIL"] || "maraudes@entourage.social"

  def welcome(user)
    return unless user.email.present?
    community = user.community

    # generate an email with an empty body
    mail { nil }

    # then overwrite the headers
    headers(
      from:    email_with_name("contact@entourage.social", "Le Réseau Entourage"),
      to:      user.email,
      subject: nil,

      'X-MJ-TemplateID' => community.mailjet_template['welcome'],
      'X-MJ-TemplateLanguage' => 1,

      'X-MJ-Vars' => JSON.fast_generate(
        first_name: user.first_name,
        user_id: UserServices::EncodedId.encode(user.id)
      ),
      'X-MJ-EventPayload' => JSON.fast_generate(
        type: :welcome,
        user_id: user.id
      ),
      'X-Mailjet-Campaign' => community_prefix(community, :welcome)
    )
  end

  def entourage_confirmation(entourage)
    user = entourage.user
    return unless user.email.present?

    # generate an email with an empty body
    mail { nil }

    # then overwrite the headers
    headers(
      from:    email_with_name("guillaume@entourage.social", "Le Réseau Entourage"),
      to:      user.email,
      subject: nil,

      'X-MJ-TemplateID' => 312279,
      'X-MJ-TemplateLanguage' => 1,

      'X-MJ-Vars' => JSON.fast_generate(
        first_name: user.first_name,
        entourage_title: entourage.title
      ),
      'X-MJ-EventPayload' => JSON.fast_generate(
        type: :action_confirmation,
        entourage_id: entourage.id
      ),
      'X-Mailjet-Campaign' => :action_confirmation
    )
  end

  def action_zone_suggestion(user, postal_code)
    return unless user.email.present?
    user_id = UserServices::EncodedId.encode(user.id)

    # generate an email with an empty body
    mail { nil }

    # then overwrite the headers
    headers(
      from:    email_with_name("guillaume@entourage.social", "Le Réseau Entourage"),
      to:      user.email,
      subject: nil,

      'X-MJ-TemplateID' => 355675,
      'X-MJ-TemplateLanguage' => 1,

      'X-MJ-Vars' => JSON.fast_generate(
        first_name: user.first_name,
        postal_code: postal_code,
        user_id: user_id,
        confirm_url: confirm_api_v1_action_zones_url(
          host: API_HOST,
          protocol: :https,
          user_id: user_id,
          postal_code: postal_code
        )
      ),
      'X-MJ-EventPayload' => JSON.fast_generate(
        type: :action_zone_suggestion,
        user_id: user.id
      ),
      'X-Mailjet-Campaign' => :action_zone_suggestion
    )
  end

  def action_zone_confirmation(user, postal_code)
    return unless user.email.present?

    # generate an email with an empty body
    mail { nil }

    # then overwrite the headers
    headers(
      from:    email_with_name("guillaume@entourage.social", "Le Réseau Entourage"),
      to:      user.email,
      subject: nil,

      'X-MJ-TemplateID' => 335020,
      'X-MJ-TemplateLanguage' => 1,

      'X-MJ-Vars' => JSON.fast_generate(
        first_name: user.first_name,
        postal_code: postal_code,
      ),
      'X-MJ-EventPayload' => JSON.fast_generate(
        type: :action_zone_confirmation,
        user_id: user.id
      ),
      'X-Mailjet-Campaign' => :action_zone_confirmation
    )
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
      'X-Mailjet-Campaign' => :tour_report
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

  def handle_delivery_error exception
    case exception.message
    when '401 4.1.3 Bad recipient address syntax'
      # Do nothing for now
      # TODO: handle badly formatted email addresses
    else
      # This will let Sidekiq retry the later in case of an async job
      raise exception
    end
  end

  def email_with_name(email, name)
    %("#{name}" <#{email}>)
  end

  def community_prefix community, identifier
    prefix = community == :entourage ? nil : community.slug
    [prefix, identifier].compact.map(&:to_s).join('_')
  end
end

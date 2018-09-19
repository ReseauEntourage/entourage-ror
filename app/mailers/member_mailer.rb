class MemberMailer < ActionMailer::Base
  default from: "contact@entourage.social"
  add_template_helper(OrganizationHelper)

  rescue_from Net::ProtocolError, with: :handle_delivery_error

  include EmailDeliveryHooks::Concern

  COMMUNITY_EMAIL   = ENV["COMMUNITY_EMAIL"]   || "communaute@entourage.social"
  TOUR_REPORT_EMAIL = ENV["TOUR_REPORT_EMAIL"] || "maraudes@entourage.social"

  def welcome(user)
    community = user.community
    mailjet_email to: user,
                  template_id: community.mailjet_template['welcome'],
                  campaign_name: community_prefix(community, :welcome),
                  from: email_with_name("contact@entourage.social", "Le Réseau Entourage")
  end

  def entourage_confirmation(entourage)
    user = entourage.user
    mailjet_email to: user,
                  template_id: 312279,
                  campaign_name: :action_confirmation,
                  variables: {
                    entourage_title: entourage.title
                  },
                  payload: {
                    entourage_id: entourage.id
                  }
  end

  def action_zone_suggestion(user, postal_code)
    mailjet_email to: user,
                  template_id: 355675,
                  campaign_name: :action_zone_suggestion,
                  variables: {
                    postal_code: postal_code,
                    confirm_url: confirm_api_v1_action_zones_url(
                      host: API_HOST,
                      protocol: :https,
                      user_id: UserServices::EncodedId.encode(user.id),
                      postal_code: postal_code
                    )
                  }
  end

  def action_zone_confirmation(user, postal_code)
    mailjet_email to: user,
                  template_id: 335020,
                  campaign_name: :action_zone_confirmation,
                  variables: {
                    postal_code: postal_code,
                  }
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

  def mailjet_email to:, template_id:, campaign_name:,
                    from: email_with_name("guillaume@entourage.social", "Le Réseau Entourage"),
                    groups: {},
                    variables: {},
                    payload: {}
    user = to
    return unless user.email.present?

    groups.each do |name, group|
      variables.reverse_merge!(
        "#{name}_title".to_sym => group.title,
        "#{name}_url".to_sym => "#{ENV['WEBSITE_URL']}/entourages/#{group.uuid_v2}",
        "#{name}_share_url".to_sym => "#{ENV['WEBSITE_URL']}/entourages/#{group.uuid_v2}?auth=false",
      )
    end

    variables.reverse_merge!(
      first_name: user.first_name,
      user_id: UserServices::EncodedId.encode(user.id),
      webapp_login_link: (ENV['WEBSITE_URL'] + '/app'),
      login_link: (ENV['WEBSITE_URL'] + '/deeplink/feed')
    )

    # inject auth tokens in webapp URLs
    webapp_regex = %r{^#{ENV['WEBSITE_URL']}/(app|deeplink|entourages)([/\?]|$)}
    auth_token = UserServices::UserAuthenticator.auth_token(user)
    variables.each_value do |value|
      next unless value.is_a?(String) && value.match(webapp_regex) != nil
      uri = URI(value)
      params = CGI.parse(uri.query || '')
      if params['auth'] == ['false']
        params.delete('auth')
      else
        params['auth'] = auth_token
      end
      uri.query = params.any? ? URI.encode_www_form(params) : nil
      value.replace uri.to_s
    end

    payload.reverse_merge!(
      type: campaign_name,
      user_id: user.id,
    )

    # generate an email with an empty body
    mail { nil }

    # then overwrite the headers
    headers(
      from:    from,
      to:      user.email,
      subject: nil,

      'X-MJ-TemplateID' => template_id,
      'X-MJ-TemplateLanguage' => 1,
      'X-MJ-TemplateErrorReporting' => 'jq3pq6ub@robot.zapier.com',

      'X-MJ-Vars' => JSON.fast_generate(variables),
      'X-MJ-EventPayload' => JSON.fast_generate(payload),
      'X-Mailjet-Campaign' => campaign_name
    )

    if ENV['MAILJET_SAMPLING_ADDRESS'].present?
      rate = Float(ENV['MAILJET_SAMPLING_RATE'] || 0.02)
      collect_samples rate: rate, address: ENV['MAILJET_SAMPLING_ADDRESS']
    end
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
    case exception.message.chomp
    when '401 4.1.3 Bad recipient address syntax',
         '501 5.1.3 Bad recipient address syntax'
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

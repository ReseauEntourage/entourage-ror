class MailjetMailer < ActionMailer::Base
  include EmailDeliveryHooks::Concern
  include MailerHelpers
  include MailerErrorHandling

  def mailjet_email to:, template_id:, campaign_name:,
                    from: email_with_name("guillaume@entourage.social", "Le Réseau Entourage"),
                    variables: {},
                    payload: {},
                    unsubscribe_category: :default,
                    deliver_only_once: false

    user = to
    return unless user.email.present? &&
                  EmailPreferencesService.accepts_emails?(
                    user: user, category: unsubscribe_category)

    merge_default_variables = true
    default_variables = {
      first_name: UserPresenter.format_first_name(user.first_name),
      user_id: UserServices::EncodedId.encode(user.id),
      webapp_login_link: (ENV['WEBSITE_URL'] + '/app'),
      login_link: (ENV['WEBSITE_URL'] + '/deeplink/feed')
    }

    group_variables = {
      '_title'     => ->(group) { group.title },
      '_url'       => ->(group) { "#{ENV['WEBSITE_APP_URL']}/actions/#{group.uuid_v2}" },
      '_share_url' => ->(group) { "#{ENV['WEBSITE_APP_URL']}/actions/#{group.uuid_v2}?auth=false" }
    }
    # reorder by suffix length for longest-suffix match
    group_variables = Hash[group_variables.sort_by { |s, _| s.length }.reverse]


    # converts
    #   variables: [
    #     :first_name,
    #     :login_link,
    #     other_var: :some_value
    #   ]
    # to
    #   variables: {
    #     first_name: default_variables[:first_name],
    #     login_link: default_variables[:login_link],
    #     other_var: :some_value
    #   }
    if variables.is_a?(Array)
      array = variables
      variables = {}
      array.each do |var|
        case
        when var.is_a?(Hash)
          variables.merge! var
        when default_variables.key?(var)
          variables[var] = default_variables[var]
          merge_default_variables = false
        else
          raise "variable #{var.inspect} can't be generated automatically"
        end
      end
    end


    # converts
    #   variables: {
    #     entourage => [:event_url, :event_share_url]
    #   }
    # to
    #   variables: {
    #     event_url: group_url(entourage),
    #     event_share_url: group_share_url(event)
    #   }
    new_variables = {}
    variables.each do |group, variable_names|
      next unless group.is_a?(Entourage)
      Array(variable_names).each do |variable_name|
        _, f = group_variables.find { |suffix, _| variable_name.to_s.ends_with?(suffix) }

        if f.nil?
          raise "#{variable_name.inspect} doesn't match any known suffix. " \
                "Possible suffixes are: #{group_variables.keys.join(', ')}."
        end

        if variables.key?(variable_name)
          raise "Variable #{variable_name.inspect} is already defined."
        end

        variables.delete(group)
        new_variables[variable_name] = f[group]
      end
    end

    variables.reverse_merge!(new_variables)
    variables.reverse_merge!(default_variables) if merge_default_variables

    # inject auth tokens in webapp URLs
    webapp_regex = %r{^#{ENV['WEBSITE_URL']}/(app|deeplink|entourages)([/\?]|$)}
    website_app_regex = %r{^#{ENV['WEBSITE_APP_URL']}/actions([/\?]|$)}

    auth_token = UserServices::UserAuthenticator.auth_token(user)
    variables.each_value do |value|
      next unless value.is_a?(String) && (value.match(webapp_regex) != nil || value.match(website_app_regex) != nil)
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

    variables.reverse_merge!(
      unsubscribe_url: EmailPreferencesService.update_url(
                         user: user, accepts_emails: false, category: unsubscribe_category)
    )

    payload.reverse_merge!(
      type: campaign_name,
      user_id: user.id,
      unsubscribe_category: unsubscribe_category
    )

    # Generate an email with an empty part.
    # This is required so that attachments will be the second and later parts,
    # which is needed for attachments to work with Mailjet.
    mail do |format|
      format.text { nil }
    end

    # then overwrite the headers
    headers(
      from:    from,
      to:      user.email,
      subject: nil,

      'X-MJ-TemplateID' => template_id,
      'X-MJ-TemplateLanguage' => 1,
      'X-MJ-TemplateErrorReporting' => 'mailjet-errors.o612mj@zapiermail.com',

      'X-MJ-Vars' => JSON.fast_generate(variables),
      'X-MJ-EventPayload' => JSON.fast_generate(payload),
      'X-Mailjet-Campaign' => campaign_name
    )

    track_delivery(
      user_id: user.id,
      campaign: campaign_name,
      deliver_only_once: deliver_only_once,
      detailed: true
    )

    if ENV['MAILJET_SAMPLING_ADDRESS'].present?
      rate = Float(ENV['MAILJET_SAMPLING_RATE'] || 0.02)
      collect_samples rate: rate, address: ENV['MAILJET_SAMPLING_ADDRESS']
    end
  end
end

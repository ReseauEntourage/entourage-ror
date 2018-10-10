namespace :community do
  task update_typeform_webhooks: :environment do
    $server_community.links
      .find_all { |key, _|
        key =~ /^ethics-charter(-pro)?#{ '-preprod' if ENV['STAGING'] }$/
      }
      .each do |key, url|
        form_id = URI(url).path.match(%r(/to/(?<id>[^/]*)))[:id]
        tag = "#{$server_community.slug}_#{key}"
        url =
          Rails.application.routes.url_helpers
            .ethics_charter_signed_api_v1_users_url(
              host: API_HOST, protocol: :https)
        endpoint = "https://api.typeform.com/forms/#{form_id}/webhooks/#{tag}"
        body = {url: url, enabled: true}

        puts endpoint
        puts JSON.pretty_generate(body)

        response = HTTParty.put(
          endpoint,
          headers: {
            authorization: "bearer #{ENV['TYPEFORM_TOKEN']}",
            content_type: 'application/json'
          },
          body: JSON.fast_generate(body)
        )

        response_body = JSON.pretty_generate(JSON.parse(response.body)) rescue response.body
        puts response.code
        puts response_body
        puts
      end
  end
end

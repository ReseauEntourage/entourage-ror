Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.environment = Rails.env
  config.enabled_environments = ['production']
  config.breadcrumbs_logger = [:active_support_logger]
  config.send_default_pii = true
  config.excluded_exceptions += ['Rack::Timeout::RequestTimeoutException']
  config.before_send = lambda do |event, hint|
    event.tags ||= {}
    event.tags[:community] = $server_community.dev_name if defined?($server_community)
    event
  end
end



module HTTParty
  module ClassMethods
    private

    alias_method :_perform_request, :perform_request

    def perform_request(http_method, path, options, &block)
      _perform_request(http_method, path, options, &block).tap do |response|
        begin
          Sentry.add_breadcrumb(
            Sentry::Breadcrumb.new(
              category: 'httparty.request',
              data: {
                method: http_method.name.demodulize.upcase,
                url: path,
                options: options,
                code: response.code,
                response: response.parsed_response
              }
            )
          )
        rescue => e
          Rails.logger.warn "[Sentry] Failed to add breadcrumb: #{e.message}"
        end
      end
    end
  end
end

Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.environment = Rails.env
  config.enabled_environments = ['production']
  config.breadcrumbs_logger = [:active_support_logger]

  config.before_send = lambda do |event, hint|
    filter_parameters = Rails.application.config.filter_parameters.map(&:to_s)
    event.request.data.each do |key, value|
      if filter_parameters.include?(key)
        event.request.data[key] = '[FILTERED]'
      end
    end
    event
  end

  config.excluded_exceptions += ['Rack::Timeout::RequestTimeoutException']
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
        rescue
        end
      end
    end
  end
end

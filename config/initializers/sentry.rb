Raven.configure do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.current_environment = Rails.env
  config.environments = ['production']
  config.rails_activesupport_breadcrumbs = true
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
  config.processors -= [Raven::Processor::PostData]
  config.tags.merge(community: $server_community.dev_name)
end


module HTTParty
  module ClassMethods
    private

    alias_method :_perform_request, :perform_request

    def perform_request(http_method, path, options, &block)
      _perform_request(http_method, path, options, &block).tap do |response|
        begin
          Raven.breadcrumbs.record do |crumb|
            crumb.data = {
              method: http_method.name.demodulize.upcase,
              url: path,
              options: options,
              code: response.code,
              response: response.parsed_response
            }
            crumb.category = 'httparty.request'
          end
        rescue
        end
      end
    end
  end
end

# https://github.com/rpush/rpush/blob/v2.7.0/lib/rpush/daemon/gcm/delivery.rb
require 'rpush/daemon'
module Rpush
  module Daemon
    module Gcm
      class Delivery < Rpush::Daemon::Delivery
        protected

        alias_method :_handle_response, :handle_response

        def handle_response(response)
          _handle_response(response)
        rescue Rpush::DeliveryError => e
          Sentry.capture_exception(
            e,
            extra: {
              notification_id: @notification.id,
              response_code: response.code.to_i,
              response_body: response.body,
            }
          ) unless response.code.to_i == 200
          raise e
        end
      end
    end
  end
end

# TODO: this is a hack to quickfix my dev env
#       we must figure out the right way to fix the issue
module Rpush
  module Daemon
    class TcpConnection
      protected

      alias_method :_setup_ssl_context, :setup_ssl_context

      def setup_ssl_context
        _setup_ssl_context.tap do |context|
          # https://www.openssl.org/docs/man1.1.0/man3/SSL_CTX_get_security_level.html
          context.security_level = 1 # was 2
        end
      end
    end
  end
end if Rails.env.development?

redis_url = ENV["HEROKU_REDIS_GOLD_URL"] || ENV["REDIS_URL"]

Sidekiq.configure_server do |config|
  ActiveSupport.on_load(:after_initialize) do
    Rpush.embed unless Rails.env.test? || ENV['DISABLE_RPUSH'] == 'true'
  end

  config.redis = {
    url: redis_url,
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
      url: redis_url,
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }
end

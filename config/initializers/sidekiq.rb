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
          Raven.capture_exception(
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

Sidekiq.configure_server do |config|
  ActiveSupport.on_load(:after_initialize) do
    Rpush.embed unless Rails.env.test? || ENV['DISABLE_RPUSH'] == 'true'
  end
end

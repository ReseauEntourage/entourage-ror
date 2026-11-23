module Api
  module V1
    module Assistant
      # Base of the routes reserved to the Entourage AI assistant.
      #
      # It deliberately does not inherit from Api::V1::BaseController: the assistant only
      # reads, so it must never trigger what authenticating a user does there (last sign in,
      # Salesforce sync, session tracking, route completion job, Sentry params, API key in the
      # logs). It is an ActionController::API: no session, no cookie, no CSRF.
      #
      # Two checks, in this order, before any account is read:
      # 1. the API key dedicated to the assistant (ASSISTANT_API_KEY, header X-API-KEY);
      # 2. the token of the user, read from `Authorization: Bearer <token>` only, never from
      #    the parameters (so it is never in the URL, the logs or the error tracker).
      class BaseController < ActionController::API
        BEARER = /\ABearer\s+(\S+)\z/i

        before_action :authenticate_assistant!
        before_action :authenticate_user_from_header!

        private

        attr_reader :assistant_user

        def authenticate_assistant!
          return if valid_api_key?

          render_error(code: 'INVALID_API_KEY', message: 'Missing or invalid API key.', status: :unauthorized)
        end

        # Compares digests so that the comparison takes the same time whatever the key.
        # An empty or unset ASSISTANT_API_KEY refuses every request: the empty key is never valid.
        def valid_api_key?
          expected = ENV['ASSISTANT_API_KEY'].to_s
          provided = request.headers['X-API-KEY'].to_s

          same = ActiveSupport::SecurityUtils.secure_compare(
            Digest::SHA256.hexdigest(expected),
            Digest::SHA256.hexdigest(provided)
          )
          same && expected.present?
        end

        def authenticate_user_from_header!
          token = bearer_token
          return render_invalid_token if token.blank?

          if AnonymousUserService.token?(token, community: $server_community)
            return render_error(
              code: 'ANONYMOUS_ACCOUNT',
              message: 'Anonymous accounts cannot use the assistant.',
              status: :forbidden
            )
          end

          # Scoped to the community of the server: a token of another community (same table) is unknown here.
          user = $server_community.users.eager_load(:address).find_by(token: token)
          # Same refusal as an invalid token: nothing says what the state of the account is.
          return render_invalid_token unless user && usable?(user)

          @assistant_user = user
        end

        def usable?(user)
          !user.deleted && !user.blocked? && !user.anonymized?
        end

        def bearer_token
          BEARER.match(request.headers['Authorization'].to_s.strip)&.captures&.first
        end

        # Coordinates of a city given by the assistant, as search parameters. Without a city, or with
        # the city of the profile, the search starts from the address of the user (no geocoding, the
        # text does not leave Local). Another city is geocoded (Assistant::PlaceGeocoder).
        def coordinates_for_city city
          city = city.to_s.strip
          return {} if city.blank?
          return {} if city.casecmp?(assistant_user.address&.city.to_s)

          place = ::Assistant::PlaceGeocoder.locate(city)
          { latitude: place.latitude, longitude: place.longitude }
        rescue ::Assistant::PlaceGeocoder::NotFound
          render_error(code: 'PLACE_NOT_FOUND', message: 'This place is not known.', status: :not_found)
          nil
        end

        def render_invalid_token
          render_error(code: 'INVALID_TOKEN', message: 'Missing or invalid token.', status: :unauthorized)
        end

        def render_error(code:, message:, status:)
          render json: { error: { code: code, message: message } }, status: status
        end

        # The uuid of the user is the only thing about them that the logs carry (Lograge). The
        # parameters are not logged at all: they hold the texts of the person (search words, a
        # message, a publication), and the ids already are in the path.
        def append_info_to_payload(payload)
          super
          payload[:user] = assistant_user&.uuid
          payload[:params] = {}
        end
      end
    end
  end
end

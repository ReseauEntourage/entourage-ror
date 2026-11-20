module Assistant
  module Actions
    # Publishes a request or an offer of help in the name of the user, with the services of the app
    # (EntourageServices::SolicitationBuilder and ContributionBuilder). The text is the one given
    # by the assistant, untouched.
    #
    # As in the app, a request is only open (visible) when the person's consent is obtained
    # (`recipient_consent_obtained`): without it, the request waits for the moderation.
    class PublishHelp < Base
      TYPES = %w[request offer].freeze

      def initialize user:, type:, params:
        super(user: user)
        @type = type
        @params = params
      end

      def call
        refuse!(400, 'INVALID_PARAMS', 'type must be request or offer.') unless TYPES.include?(@type)
        require_param!(@params[:title], 'title')

        action = nil
        builder.create do |on|
          on.success { |created| action = created }
          on.failure { |failed| refuse_with_errors!(failed, 'CANNOT_PUBLISH', 'Could not publish.') }
        end

        outcome(201, { id: action.uuid_v2, type: @type, status: action.status }, action)
      end

      private

      def builder
        attributes = @params.slice(:title, :description, :section, :postal_code).to_h
        attributes[:recipient_consent_obtained] = @params[:recipient_consent_obtained] if @type == 'request'
        attributes[:location] = {
          latitude: @params[:latitude].presence || user.latitude,
          longitude: @params[:longitude].presence || user.longitude
        }
        permitted = ActionController::Parameters.new(attributes).permit!

        if @type == 'request'
          ::EntourageServices::SolicitationBuilder.new(params: permitted, user: user)
        else
          ::EntourageServices::ContributionBuilder.new(params: permitted, user: user)
        end
      end
    end
  end
end

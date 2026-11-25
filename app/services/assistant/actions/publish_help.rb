module Assistant
  module Actions
    # Publishes a request or an offer of help in the name of the user, with the services of the app
    # (EntourageServices::SolicitationBuilder and ContributionBuilder). The title and the description
    # are the ones given by the assistant (they are in the preview the person confirmed), untouched
    # but for the normalization of the model, as for any publication of the app.
    #
    # As in the app, a request is only open (visible) when the consent of the person is obtained
    # (`recipient_consent_obtained`): without it, the request waits for the moderation. The place is
    # the address of the user.
    class PublishHelp < Base
      TYPES = %w[request offer].freeze

      # @param params [Hash] title, description, category (a category of the app), recipient_consent_obtained
      def initialize user:, type:, params:
        super(user: user)
        @type = type
        @params = params
      end

      def call
        refuse!(400, 'INVALID_PARAMS', 'type must be request or offer.') unless TYPES.include?(@type)
        require_param!(@params[:title], 'title')
        category = @params[:category].to_s
        unless ::Tag.sections.key?(category.to_sym) && category.present?
          refuse!(400, 'INVALID_PARAMS', 'category must be one of the categories of /help_categories.', [category.present? ? 'category is not a category of the app' : 'category is missing'])
        end
        refuse!(400, 'INVALID_PARAMS', 'The user has no address to publish from.') if user.latitude.blank? || user.longitude.blank?

        action = nil
        builder.create do |on|
          on.success { |created| action = created }
          on.failure { |failed| refuse_with_errors!(failed, 'CANNOT_PUBLISH', 'Could not publish.') }
        end

        outcome(201, { id: action.uuid_v2, type: @type, status: action.status }, action)
      end

      private

      def builder
        attributes = { title: @params[:title], description: @params[:description], section: @params[:category] }
        attributes[:recipient_consent_obtained] = @params[:recipient_consent_obtained] if @type == 'request'
        attributes[:location] = { latitude: user.latitude, longitude: user.longitude }
        permitted = ActionController::Parameters.new(attributes.compact).permit!

        if @type == 'request'
          ::EntourageServices::SolicitationBuilder.new(params: permitted, user: user)
        else
          ::EntourageServices::ContributionBuilder.new(params: permitted, user: user)
        end
      end
    end
  end
end

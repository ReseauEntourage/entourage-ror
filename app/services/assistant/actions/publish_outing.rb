module Assistant
  module Actions
    # Creates an outing in the name of the user with the service of the app
    # (EntourageServices::OutingBuilder), with the same validations as the creation in the app.
    # The text of the title and of the description is the one given by the assistant, untouched.
    class PublishOuting < Base
      METADATA_KEYS = %i[starts_at ends_at place_name street_address google_place_id place_limit reserved_female pmr kids_friendly].freeze

      def initialize user:, params:
        super(user: user)
        @params = params
      end

      def call
        require_param!(@params[:title], 'title')

        outing = nil
        ::EntourageServices::OutingBuilder.new(params: permitted, user: user).create do |on|
          on.success { |created| outing = created }
          on.failure { |failed| refuse_with_errors!(failed, 'CANNOT_PUBLISH', 'Could not create the outing.') }
        end

        outcome(201, { id: outing.uuid_v2, status: outing.status }, outing)
      end

      private

      def permitted
        attributes = @params.slice(:title, :description, :latitude, :longitude, :online, :event_url, :other_interest, :interests).to_h
        attributes[:metadata] = (@params[:metadata] || {}).to_h.symbolize_keys.slice(*METADATA_KEYS)

        ActionController::Parameters.new(attributes).permit!
      end
    end
  end
end

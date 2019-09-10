module Api
  module V1
    class ApiError < StandardError
      def initialize(message, params={})
        @type = params[:type]&.to_sym || :invalid_request_error
        @message = message.to_s
        @code = params[:code]&.to_i || 400
      end

      attr_reader :code

      def as_json
        {
          type: @type,
          message: @message,
        }
      end
    end
  end
end

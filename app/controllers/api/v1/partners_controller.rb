module Api
  module V1
    class PartnersController < Api::V1::BaseController
      #curl -H "Content-Type: application/json" "http://localhost:3000/api/v1/partners?token=153ad0b7ef67e5c44b8ef5afc12709e4"
      def index
        @partners = Partner.order(:name)
        render json: @partners, status: 200, each_serializer: ::V1::PartnerSerializer, scope: {minimal: true}
      end

      def show
        partner = Partner.find(params[:id])

        render json: partner, status: 200, serializer: ::V1::PartnerSerializer, scope: {
          full: true,
          following: true,
          user: current_user
        }
      end

      def join_request
        partner_join_request = current_user.partner_join_requests.new(partner_join_request_params)
        if partner_join_request.save
          render json: {}, status: 200
        else
          render_error(code: 'INVALID_PARTNER_JOIN_REQUEST', message: partner_join_request.errors.full_messages, status: 400)
        end
      end

      private

      def partner_join_request_params
        params.permit(:partner_id, :new_partner_name, :postal_code, :partner_role_title)
      end
    end
  end
end

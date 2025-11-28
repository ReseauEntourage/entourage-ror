module Api
  module V1
    class PartnersController < Api::V1::BaseController
      def index
        render json: Partner
          .active
          .search_by(params[:query])
          .order(:name)
          .page(page)
          .per(per), status: 200, each_serializer: ::V1::PartnerSerializer, scope: { minimal: true }
      end

      def show
        partner = Partner.find(params[:id])

        render json: partner, status: 200, serializer: ::V1::PartnerSerializer, scope: {
          full: true,
          following: true,
          user: current_user
        }
      end

      def create
        partner = Partner.new(partner_params.merge({ user_ids: [current_user.id] }))

        if partner.save
          render json: partner, status: 200, serializer: ::V1::PartnerSerializer, scope: {
            full: true,
            following: true,
            user: current_user
          }
        else
          render_error code: 'INVALID_PARTNER', message: partner.errors.full_messages, status: 400
        end
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

      def partner_params
        params.require(:partner).permit(
          :name, :description, :phone, :address, :website_url, :email,
          :latitude, :longitude,
          :donations_needs, :volunteers_needs,
          :staff
        )
      end

      def page
        params[:page] || 1
      end

      def per
        params[:per].try(:to_i) || 100
      end
    end
  end
end

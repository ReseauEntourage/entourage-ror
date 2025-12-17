module Api
  module V1
    class PartnersController < Api::V1::BaseController
      def index
        render json: Partner
          .active
          .search_by(params[:query])
          .inside_user_perimeter(current_user)
          .no_staff
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

      def join
        partner_id = params.require(:partner_id)

        return render_error code: 'PARTNER_NOT_FOUND', message: 'Partner not found', status: 400 unless Partner.exists?(partner_id)

        if current_user.update(partner_id: partner_id)
          render json: {}, status: 200
        else
          render_error(code: 'INVALID_PARTNER_JOIN', message: current_user.errors.full_messages, status: 400)
        end
      end

      def join_request
        render_error code: 'DEPRECATED', message: "This route is deprecated. Please use api/v1/partners/join_request instead", status: 400
      end

      private

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

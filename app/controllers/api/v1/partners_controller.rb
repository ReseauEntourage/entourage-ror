module Api
  module V1
    class PartnersController < Api::V1::BaseController
      before_action :set_partner, only: [:show, :update]

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
        render json: @partner, status: 200, serializer: ::V1::PartnerSerializer, scope: {
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

      def update
        return render json: { message: 'unauthorized' }, status: :unauthorized unless @partner.user_ids.include?(current_user.id)

        @partner.assign_attributes(partner_params)

        if @partner.save
          SlackServices::PartnerUpdate.new(
            user: current_user,
            partner: @partner
          ).notify

          render json: @partner, status: 200, serializer: ::V1::PartnerSerializer, scope: { user: current_user }
        else
          render json: {
            message: 'Could not update partner', reasons: @partner.errors.full_messages
          }, status: 400
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

      def presigned_upload
        allowed_types = Partner::CONTENT_TYPES

        unless params[:content_type].in? allowed_types
          type_list = allowed_types.to_sentence(two_words_connector: ' or ', last_word_connector: ', or ')
          return render_error(code: 'INVALID_CONTENT_TYPE', message: "Content-Type must be #{type_list}.", status: 400)
        end

        extension = MiniMime.lookup_by_content_type(params[:content_type]).extension
        key = "#{SecureRandom.uuid}.#{extension}"
        url = Partner.presigned_url(key, params[:content_type])

        render json: { upload_key: key, presigned_url: url }
      end

      private

      def set_partner
        @partner = Partner.find(params[:id])

        render json: { message: 'Could not find partner' }, status: 400 unless @partner.present?
      end

      def partner_params
        params.require(:partner).permit(
          :name, :description, :phone, :address, :website_url, :email,
          :latitude, :longitude,
          :donations_needs, :volunteers_needs,
          :image_url,
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

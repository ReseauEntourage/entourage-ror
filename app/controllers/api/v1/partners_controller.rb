module Api
  module V1
    class PartnersController < Api::V1::BaseController
      #curl -H "Content-Type: application/json" "http://localhost:3000/api/v1/partners?token=153ad0b7ef67e5c44b8ef5afc12709e4"
      def index
        # TODO(partner)
        @partners = [] # Partner.page(params[:page]).per(50)
        render json: @partners, status: 200, each_serializer: ::V1::PartnerSerializer, scope: {user: current_user, full: true}
      end
    end
  end
end
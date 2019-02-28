module Api
  module V1
    module Users
      class PartnersController < Api::V1::BaseController
        before_action :set_user

        #curl -H "Content-Type: application/json" "http://localhost:3000/api/v1/users/93/partners?token=153ad0b7ef67e5c44b8ef5afc12709e4"
        def index
          # TODO(partner)
          @partners = [] # current_user.partners.page(params[:page]).per(50)
          render json: @partners, status: 200, each_serializer: ::V1::PartnerSerializer, scope: {user: current_user}
        end

        #curl -H "Content-Type: application/json" -X POST -d '{"partner" : { "id": 3 }}' "http://localhost:3000/api/v1/users/93/partners?token=153ad0b7ef67e5c44b8ef5afc12709e4"
        def create
          # TODO(partner)
          return head status: :unprocessable_entity

          partner = Partner.find(params[:partner][:id])
          current_user.user_partners.create(partner: partner, default: true)
          mixpanel.set("Partner Badge" => partner.name)
          render json: partner, status: 201, serializer: ::V1::PartnerSerializer, scope: {user: current_user, full: true}
        end

        #curl -H "Content-Type: application/json" -X PUT -d '{"partner" : { "default": true }}' "http://localhost:3000/api/v1/users/93/partners/3?token=153ad0b7ef67e5c44b8ef5afc12709e4"
        def update
          # TODO(partner)
          return head status: :unprocessable_entity

          default = (params[:partner][:default].to_s == "true")
          partner = current_user.partners.where(partners: {id: params[:id]}).first
          current_user.user_partners.where(partner: partner).first&.update(default: default)
          mixpanel.set("Partner Badge" => current_user.default_partner.try(:name))
          render json: partner, status: 201, serializer: ::V1::PartnerSerializer, scope: {user: current_user, full: default}
        end

        #curl -H "Content-Type: application/json" -X DELETE "http://localhost:3000/api/v1/users/93/partners/3?token=153ad0b7ef67e5c44b8ef5afc12709e4"
        def destroy
          # TODO(partner)
          return head status: :unprocessable_entity

          current_user.user_partners.where(partner_id: params[:id]).destroy_all
          mixpanel.set("Partner Badge" => nil)
          head status: 204
        end

        private

        def set_user
          @user = User.find(params[:user_id])
        end
      end
    end
  end
end

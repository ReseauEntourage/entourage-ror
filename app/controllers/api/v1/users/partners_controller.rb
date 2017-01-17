module Api
  module V1
    module Users
      class PartnersController < Api::V1::BaseController
        before_action :set_user

        #curl -H "Content-Type: application/json" "http://localhost:3000/api/v1/users/93/partners?token=153ad0b7ef67e5c44b8ef5afc12709e4"
        def index
          render json: {
              "partners": [{
                               "id": 1,
                               "name": "ATD Quart Monde",
                               "large_logo_url":"https://s3-eu-west-1.amazonaws.com/entourage-ressources/ATDQM-coul-V-fr.png",
                               "small_logo_url":"https://s3-eu-west-1.amazonaws.com/entourage-ressources/Badge+image.png",
                               "default": true
                           }]
          }, status: 200
        end

        #curl -H "Content-Type: application/json" -X POST -d '{"partner" : { "id": 3 }}' "http://localhost:3000/api/v1/users/93/partners?token=153ad0b7ef67e5c44b8ef5afc12709e4"
        def create
          render json: {
              "partner": {
                  "id": 1,
                  "name": "ATD Quart Monde",
                  "large_logo_url":"https://s3-eu-west-1.amazonaws.com/entourage-ressources/ATDQM-coul-V-fr.png",
                  "small_logo_url":"https://s3-eu-west-1.amazonaws.com/entourage-ressources/Badge+image.png",
                  "default": true
              }
          }, status: 201
        end

        #curl -H "Content-Type: application/json" -X PUT -d '{"partner" : { "default": true }}' "http://localhost:3000/api/v1/users/93/partners/3?token=153ad0b7ef67e5c44b8ef5afc12709e4"
        def update
          render json: {
              "partner": {
                  "id": 1,
                  "name": "ATD Quart Monde",
                  "large_logo_url":"https://s3-eu-west-1.amazonaws.com/entourage-ressources/ATDQM-coul-V-fr.png",
                  "small_logo_url":"https://s3-eu-west-1.amazonaws.com/entourage-ressources/Badge+image.png",
                  "default": true
              }
          }, status: 200
        end

        #curl -H "Content-Type: application/json" -X DELETE "http://localhost:3000/api/v1/users/93/partners/3?token=153ad0b7ef67e5c44b8ef5afc12709e4"
        def destroy
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
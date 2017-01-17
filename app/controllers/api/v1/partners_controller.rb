module Api
  module V1
    class PartnersController < Api::V1::BaseController

      #curl -H "Content-Type: application/json" "http://localhost:3000/api/v1/partners?token=153ad0b7ef67e5c44b8ef5afc12709e4"
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

    end
  end
end
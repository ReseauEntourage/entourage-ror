module Api
  module V1
    class PartnersController < Api::V1::BaseController

      #curl -H "Content-Type: application/json" "http://localhost:3000/api/v1/partners?token=153ad0b7ef67e5c44b8ef5afc12709e4"
      def index
        render json: {
            "partners": [{
                             "id": 1,
                             "name": "foo",
                             "logo_url":"http://foo.com/bar.jpg",
                             "default": true
                         },
                         {
                             "id": 2,
                             "name": "bar",
                             "logo_url":"http://foo.com/bar.jpg",
                             "default": false
                         }]
        }, status: 200
      end

    end
  end
end
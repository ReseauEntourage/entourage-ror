module Api
  module V1
    module Salesforce
      class SfEntreprisesController < Api::V1::BaseController
        skip_before_action :authenticate_user!, only: [:index]

        def index
          entreprises = SalesforceServices::SfEntrepriseTableInterface.new
            .records_attributes(per: per, page: page)

          return render json: "[]", content_type: "application/json" if entreprises.empty?

          render json: entreprises
        end

        private

        def page
          params[:page] || 1
        end

        def per
          params[:per].try(:to_i) || 100
        end
      end
    end
  end
end

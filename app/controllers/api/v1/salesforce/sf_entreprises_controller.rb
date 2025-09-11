module Api
  module V1
    module Salesforce
      class SfEntreprisesController < Api::V1::BaseController
        skip_before_action :authenticate_user!, only: [:index]

        def index
          render json: SalesforceServices::SfEntrepriseTableInterface.new
            .records_attributes(per: per, page: page)
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

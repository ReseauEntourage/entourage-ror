module Api
  module V1
    module Salesforce
      module SfEntreprises
        class OutingsController < Api::V1::BaseController
          def index
            render json: SalesforceServices::SfEntrepriseOutingTableInterface.new(sf_entreprise_id: params[:sf_entreprise_id])
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
end

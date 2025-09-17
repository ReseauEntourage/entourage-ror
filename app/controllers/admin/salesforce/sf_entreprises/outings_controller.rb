module Admin
  module Salesforce
    module SfEntreprises
      class OutingsController < Admin::BaseController
        def index
          @interface = SalesforceServices::SfEntrepriseOutingTableInterface.new(sf_entreprise_id: params[:sf_entreprise_id])

          @records = @interface.records(per: 10, page: params[:page].to_i.positive? ? params[:page].to_i : 1)
          @outings = Kaminari.paginate_array(@records[:data], total_count: @records[:total]).page(params[:page]).per(10)
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

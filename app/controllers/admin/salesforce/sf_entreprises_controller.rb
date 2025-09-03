module Admin
  module Salesforce
    class SfEntreprisesController < Admin::BaseController
      def index
        @interface = SalesforceServices::SfEntrepriseTableInterface.new

        @records = @interface.records(per: 10, page: params[:page].to_i.positive? ? params[:page].to_i : 1)
        @sf_entreprises = Kaminari.paginate_array(@records[:data], total_count: @records[:total]).page(params[:page]).per(10)
      end
    end
  end
end

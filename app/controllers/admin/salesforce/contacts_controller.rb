module Admin
  module Salesforce
    class ContactsController < Admin::BaseController
      def index
        @interface = SalesforceServices::ContactTableInterface.new(instance: nil)

        @records = @interface.records(per: 10, page: params[:page].to_i.positive? ? params[:page].to_i : 1)
        @contacts = Kaminari.paginate_array(@records[:data], total_count: @records[:total]).page(params[:page]).per(10)
      end
    end
  end
end

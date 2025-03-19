module Admin
  module Salesforce
    class UsersController < Admin::BaseController
      def index
        @interface = SalesforceServices::UserTableInterface.new(instance: nil)

        @records = @interface.records(per: 10, page: params[:page].to_i.positive? ? params[:page].to_i : 1)
        @users = Kaminari.paginate_array(@records[:data], total_count: @records[:total]).page(params[:page]).per(10)
      end
    end
  end
end

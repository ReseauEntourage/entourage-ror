module Admin
  module Salesforce
    class UsersController < Admin::BaseController
      def index
        @interface = SalesforceServices::UserTableInterface.new(instance: nil)

        @records = @interface.records(per: 10, page: params[:page].to_i.positive? ? params[:page].to_i : 1)
        @users = Kaminari.paginate_array(@records[:data], total_count: @records[:total]).page(params[:page]).per(10)
      end

      def show
        @user = User.find(params[:id])
      end
    end
  end
end

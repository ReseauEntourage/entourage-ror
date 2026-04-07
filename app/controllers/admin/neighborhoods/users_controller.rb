module Admin
  module Neighborhoods
    class UsersController < Admin::BaseController
      before_action :set_neighborhood
      before_action :set_user

      def destroy
        @join_request = JoinRequest.where(user_id: @user.id, joinable: @neighborhood).first

        unless @join_request
          return redirect_to show_members_admin_neighborhood_path(@neighborhood), error: "Erreur : le membre n'a pas été trouvé"
        end

        if @join_request.cancelled?
          return redirect_to show_members_admin_neighborhood_path(@neighborhood), notice: "Le membre est déjà désinscrit"
        end

        @join_request.status = :cancelled

        if @join_request.save
          redirect_to show_members_admin_neighborhood_path(@neighborhood), notice: "Le membre #{@user.full_name} a été désinscrit"
        else
          redirect_to show_members_admin_neighborhood_path(@neighborhood), error: "Le membre n'a pas pu être désinscrit : #{@join_request.errors.full_messages}"
        end
      end

      private

      def set_neighborhood
        @neighborhood = Neighborhood.find(params[:neighborhood_id])
      end

      def set_user
        @user = User.find(params[:id])
      end
    end
  end
end

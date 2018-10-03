module CommunityAdmin
  class NeighborhoodsController < BaseController
    def index
      @neighborhoods =
        CommunityAdminService.coordinator_neighborhoods(current_user)
    end

    def show
      @coordinator_neighborhoods =
        CommunityAdminService.coordinator_neighborhoods(current_user)

      @neighborhood =
        @coordinator_neighborhoods
        .select(:id, :title)
        .find(params[:id])

      @users =
        CommunityAdminService.users(@neighborhood)
        .select(:id, :first_name, :last_name, :avatar_key, :validation_status, :roles, :role)
        .group_by { |u| u.role == 'coordinator' ? :coordinators : :members }
      @users.default = []
    end

    def edit
      @neighborhood =
        CommunityAdminService.coordinator_neighborhoods(current_user)
        .find(params[:id])
    end

    def update
      neighborhood =
        CommunityAdminService.coordinator_neighborhoods(current_user)
        .find(params[:id])

      neighborhood.update!(neighborhood_params)

      redirect_to community_admin_neighborhood_path(neighborhood)
    end

    def new
      @neighborhood = Entourage.new
    end

    def create
      neighborhood = Entourage.new(
        entourage_type: :contribution,
        user_id: current_user.id,
        latitude: 0,
        longitude: 0,
        group_type: :neighborhood
      )
      neighborhood.assign_attributes(neighborhood_params)

      ActiveRecord::Base.transaction do
        neighborhood.save!
        unless current_user.roles.include?(:admin)
          CommunityAdminService.add_to_group(
            user: current_user, group: neighborhood, role: :coordinator)
        end
      end

      redirect_to community_admin_neighborhood_path(neighborhood)
    end

    private

    def neighborhood_params
      params.require(:entourage).permit(:title)
    end
  end
end

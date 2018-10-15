module CommunityAdmin
  class PrivateCirclesController < BaseController
    def index
      @private_circles =
        CommunityAdminService.coordinator_private_circles(current_user)
    end

    def show
      @coordinator_private_circles =
        CommunityAdminService.coordinator_private_circles(current_user)

      @private_circle =
        @coordinator_private_circles
        .select(:id, :title, :metadata)
        .find(params[:id])

      @users =
        CommunityAdminService.users(@private_circle)
        .select(:id, :first_name, :last_name, :avatar_key, :validation_status, :roles, :role)
        .group_by { |u| u.role == 'visited' ? :visited : :visitors }
      @users.default = []
    end

    def edit
      @private_circle =
        CommunityAdminService.coordinator_private_circles(current_user)
        .find(params[:id])
    end

    def update
      private_circle =
        CommunityAdminService.coordinator_private_circles(current_user)
        .find(params[:id])

      private_circle.assign_attributes(private_circle_params)
      private_circle.metadata.merge!(private_circle_metadata_params.compact)
      private_circle.title = PrivateCircleService.generate_title(private_circle)

      private_circle.save!

      redirect_to community_admin_private_circle_path(private_circle)
    end

    def new
      @private_circle = Entourage.new
    end

    def create
      private_circle = Entourage.new(
        entourage_type: :contribution,
        user_id: current_user.id,
        group_type: :private_circle
      )
      private_circle.assign_attributes(private_circle_params)
      private_circle.metadata.merge!(private_circle_metadata_params.compact)
      private_circle.title = generate_title(private_circle)

      user =
        if params.key?(:for_user)
          find_user(params[:for_user])
        elsif !current_user.roles.include?(:admin)
          current_user
        end

      ActiveRecord::Base.transaction do
        private_circle.save!
        if user
          CommunityAdminService.add_to_group(user: user, group: private_circle)
        end
      end

      if params.key?(:for_user)
        redirect_to community_admin_user_path(user)
      else
        redirect_to community_admin_private_circle_path(private_circle)
      end
    end

    private

    def private_circle_params
      params.require(:entourage).permit(
        :latitude, :longitude, :country, :postal_code
      )
    end

    def private_circle_metadata_params
      params.require(:entourage).require(:metadata).permit(
        :visited_user_first_name, :street_address, :google_place_id
      )
    end

    def find_user id
      @coordinator_neighborhoods, @coordinator_users =
        CommunityAdminService.coordinator_neighborhoods_and_users(current_user)

      @coordinator_users.find(id)
    end
  end
end

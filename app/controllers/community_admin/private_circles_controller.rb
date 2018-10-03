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
        .select(:id, :title)
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

      private_circle.update!(private_circle_params)

      redirect_to community_admin_private_circle_path(private_circle)
    end

    def new
      @private_circle = Entourage.new
    end

    def create
      private_circle = Entourage.new(
        entourage_type: :contribution,
        user_id: current_user.id,
        latitude: 0,
        longitude: 0,
        group_type: :private_circle
      )
      private_circle.assign_attributes(private_circle_params)

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

    def generate_title first_name
      if "aehiouy".include?(first_name.first.downcase)
        "Les amis d'#{first_name}"
      else
        "Les amis de #{first_name}"
      end
    end

    def private_circle_params
      begin
        params[:entourage] ||= {}
        params[:entourage][:title] = generate_title(params[:visited_user_first_name])
      rescue
      end
      params.require(:entourage).permit(:title)
    end

    def find_user id
      @coordinator_neighborhoods, @coordinator_users =
        CommunityAdminService.coordinator_neighborhoods_and_users(current_user)

      @coordinator_users.find(id)
    end
  end
end

module CommunityAdmin
  class NeighborhoodsController < BaseController
    def index
      @neighborhoods =
        CommunityAdminService.coordinator_neighborhoods(current_user)

      has_pending = %{
        count(
          case when member_join_requests.status = 'pending' then 1 end
        ) > 0
      }

      @neighborhoods = @neighborhoods
        .joins(%{
          left join
            join_requests member_join_requests
          on
            member_join_requests.joinable_id = entourages.id and
            member_join_requests.joinable_type = 'Entourage' and
            member_join_requests.status = 'pending'
        })
        .select(:id, :title)
        .group(:id)
        .select("#{has_pending} as has_pending")
        .order("#{has_pending} desc")
    end

    def show
      @coordinator_neighborhoods =
        CommunityAdminService.coordinator_neighborhoods(current_user)

      @neighborhood =
        @coordinator_neighborhoods
        .select(:id, :title, :metadata)
        .find(params[:id])

      @users =
        CommunityAdminService.users(@neighborhood)
        .select(:id, :first_name, :last_name, :avatar_key, :validation_status, :roles, :role, 'join_requests.status')
        .order("join_requests.status desc")
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

      neighborhood.assign_attributes(neighborhood_params)
      if params[:entourage].key?(:metadata)
        neighborhood.metadata.merge!(neighborhood_metadata_params.compact)
      end

      neighborhood.save!

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
      neighborhood.metadata.merge!(neighborhood_metadata_params.compact)

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
      params.require(:entourage).permit(
        :title, :description,
        :latitude, :longitude, :country, :postal_code
      )
    end

    def neighborhood_metadata_params
      params.require(:entourage).require(:metadata).permit(
        :address, :google_place_id
      )
    end
  end
end

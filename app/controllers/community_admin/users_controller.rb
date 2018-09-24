module CommunityAdmin
  class UsersController < BaseController
    def index
      @neighborhoods, @users = CommunityAdminService
        .coordinator_neighborhoods_and_users(current_user)

      @neighborhoods = @neighborhoods.select(:id, :title)
      @neighborhoods = Hash[@neighborhoods.map { |n| [n.id, n] }]

      if current_user.roles.include?(:admin)
        @neighborhoods =
          {none: Entourage.new(title: "Membre d'aucun voisinage")}.merge(@neighborhoods)
      end

      all_neighborhoods = @neighborhoods.keys
      neighborhood_ids = Array(params[:neighborhoods])
                         .map { |p| p == 'none' ? :none : p.to_i }
                         .uniq & all_neighborhoods
      neighborhood_ids = all_neighborhoods if neighborhood_ids.empty?

      @filters = {
        neighborhoods: {
          ids: neighborhood_ids,
          is_filtered: neighborhood_ids != all_neighborhoods
        }
      }

      if @filters[:neighborhoods][:is_filtered]
        @users = CommunityAdminService
          .coordinator_users_filtered(current_user, neighborhood_ids)
      end
      @users = @users.select(
        :id, :first_name, :last_name, :avatar_key, :validation_status, :roles)
    end

    def show
      @user = find_user(params[:id])

      @user_neighborhoods =
        @coordinator_neighborhoods
        .joins(:join_requests)
        .merge(@user.join_requests.accepted)
        .select("entourages.id, entourages.title, join_requests.role")
    end

    def edit
      @user = find_user(params[:id])
    end

    def update
      user = find_user(params[:id])

      modifiable_roles = CommunityAdminService.modifiable_roles(by: current_user, of: user)
      persisted_roles = user.roles - modifiable_roles
      submitted_roles = (user_params[:roles] || []).map(&:to_sym)

      user.assign_attributes(user_params)
      user.roles = (submitted_roles & modifiable_roles) + persisted_roles

      downgrade_neighborhood_roles =
        user.roles_change &&
        (user.roles_change.first - user.roles_change.last).include?(:coordinator)

      user.save!

      if downgrade_neighborhood_roles
        user.join_requests
            .joins(:entourage)
            .merge(@coordinator_neighborhoods)
            .where(role: :coordinator)
            .update_all(role: :member)
      end

      redirect_to community_admin_user_path(user)
    end

    def update_neighborhood_role
      raise unless CommunityAdminService.coordinator_neighborhoods(current_user)
                                        .where(id: params[:neighborhood_id])
                                        .exists?

      user = User.find(params[:user_id])

      raise if params[:role] == 'member' &&
               user == current_user &&
               CommunityAdminService.leaving_neigborhood_will_lock_out(user)

      join_request = user.join_requests.accepted.find_by!(
        joinable_id: params[:neighborhood_id]
      )

      raise unless params[:role].in? ['coordinator', 'member']

      join_request.update_column(:role, params[:role])

      should_be_coordinator = user.join_requests.accepted.where(role: :coordinator).exists?
      is_coordinator = user.roles.include?(:coordinator)
      if should_be_coordinator && !is_coordinator
        user.roles.push :coordinator
      elsif !should_be_coordinator && is_coordinator
        user.roles.delete :coordinator
      end
      user.save! if user.changed?

      redirect_to community_admin_user_path(user)
    end

    def add_to_neighborhood
      raise unless CommunityAdminService.coordinator_neighborhoods(current_user)
                                        .where(id: params[:neighborhood_id])
                                        .exists?

      user = find_user(params[:user_id])

      join_request = JoinRequest.find_or_initialize_by(
        user_id: params[:user_id],
        joinable_id: params[:neighborhood_id],
        joinable_type: :Entourage
      )

      join_request.status = :accepted
      join_request.role ||= :member

      join_request.save! if join_request.new_record? || join_request.changed?

      redirect_to community_admin_user_path(user)
    end

    def remove_from_neighborhood
      raise unless CommunityAdminService.coordinator_neighborhoods(current_user)
                                        .where(id: params[:neighborhood_id])
                                        .exists?

      user = User.find(params[:user_id])

      join_request = user.join_requests.accepted.find_by!(
        joinable_id: params[:neighborhood_id]
      )

      raise if join_request.role == 'coordinator' &&
               user == current_user &&
               CommunityAdminService.leaving_neigborhood_will_lock_out(user)

      join_request.destroy

      if join_request.role == 'coordinator'
        should_be_coordinator = user.join_requests.accepted.where(role: :coordinator).exists?
        is_coordinator = user.roles.include?(:coordinator)
        if  !should_be_coordinator && is_coordinator
          user.roles.delete :coordinator
        end
        user.save! if user.changed?
      end

      redirect_to community_admin_user_path(user)
    end

    def new
      @user = User.new
    end

    def create
      builder = UserServices::PublicUserBuilder.new(params: user_params, community: community)
      builder.create(send_sms: false, sms_code: '123456') do |on|
        on.success do |user|
          return redirect_to community_admin_user_path(user)
        end
      end
      raise :error
    end


    private

    def find_user id
      @coordinator_neighborhoods, @coordinator_users =
        CommunityAdminService.coordinator_neighborhoods_and_users(current_user)

      @coordinator_users.find(id)
    end

    def user_params
      params.require(:user).permit(
        :first_name, :last_name,
        :phone, :email,
        roles: []
      )
    end
  end
end

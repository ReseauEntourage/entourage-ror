module CommunityAdmin
  class UsersController < BaseController
    def index
      @neighborhoods = CommunityAdminService.coordinator_neighborhoods(current_user)

      @neighborhoods = @neighborhoods.select(:id, :title)
      @neighborhoods = Hash[@neighborhoods.map { |n| [n.id, n] }]

      if current_user.roles.include?(:admin)
        @neighborhoods =
          {none: Entourage.new(title: "Membre d'aucun voisinage de quartier")}.merge(@neighborhoods)
      end

      all_neighborhoods = @neighborhoods.keys
      neighborhood_ids = Array(params[:neighborhoods])
                         .map { |p| p == 'none' ? :none : p.to_i }
                         .uniq & all_neighborhoods
      neighborhood_ids = all_neighborhoods if neighborhood_ids.empty?

      neighborhood_status = params[:neighborhood_status]&.to_sym
      neighborhood_status = nil unless neighborhood_status.in?([:accepted, :pending])

      roles = Array(params[:roles]).map(&:to_sym).uniq & community.roles
      roles = community.roles if roles.empty?

      roles_operator = params[:roles_op] == 'and' ? :and : :or

      has_private_circle =
        case params[:has_private_circle]
        when *ActiveRecord::ConnectionAdapters::Column::TRUE_VALUES
          true
        when *ActiveRecord::ConnectionAdapters::Column::FALSE_VALUES
          false
        else
          nil
        end

      @filters = {
        neighborhoods: {
          ids: neighborhood_ids,
          status: neighborhood_status,
          ids_filtered: neighborhood_ids != all_neighborhoods,
          is_filtered: neighborhood_ids != all_neighborhoods || neighborhood_status != nil
        },
        roles: {
          list: roles,
          operator: roles_operator,
          is_filtered: roles_operator == :and || roles.count != community.roles.count
        },
        has_private_circle: {
          value: has_private_circle,
          is_filtered: has_private_circle != nil
        }
      }

      @for_group = find_group(params[:for_group]) if params.key?(:for_group)

      @users = CommunityAdminService.coordinator_users_filtered(
        current_user,
        neighborhood_ids,
        has_private_circle: has_private_circle,
        neighborhood_status: neighborhood_status
      )

      if @filters[:roles][:is_filtered]
        operator = roles_operator == :and ? '?&' : '?|'
        @users = @users.where("roles #{operator} array[#{ roles.map { |r| ActiveRecord::Base.connection.quote(r) }.join(',') }]")
      end

      @users = @users.select(
        :id, :first_name, :last_name, :avatar_key, :validation_status, :roles)

      if @for_group
        group = "ST_SetSRID(ST_MakePoint(#{@for_group.longitude}, #{@for_group.latitude}), 4326)"
        user  = "ST_SetSRID(ST_MakePoint(addresses.longitude, addresses.latitude), 4326)"
        @users = @users
          .joins("left join addresses on addresses.id = users.address_id")
          .select(%{
            case
            when addresses is null then null
            else ST_Distance(#{group}, #{user}, false)
            end as distance
          })
          .group("addresses, addresses.latitude, addresses.longitude")
          .order("#{group} <-> #{user}")
      else
        join_request_pending = %{
          array_position(
            array_agg(
              case when coalesce(neighborhoods.id, private_circles.id) is not null then
                join_requests.status
              end),
            'pending')
          is not null
        }
        @users = @users
          .select("#{join_request_pending} as join_request_pending")
          .order("#{join_request_pending} desc", :last_name, :first_name)
      end
    end

    def archived
      _, @users = CommunityAdminService.coordinator_neighborhoods_and_users(current_user)
      @users = @users.where(deleted: true)
    end

    def show
      @user = find_user(params[:id])

      @user_neighborhoods =
        @coordinator_neighborhoods
        .joins(:join_requests)
        .merge(@user.join_requests.where(status: [:pending, :accepted]))
        .select("entourages.id, entourages.title, join_requests.role, join_requests.status")
        .order("join_requests.status desc")

      @coordinator_private_circles =
        CommunityAdminService.coordinator_private_circles(current_user)

      @user_private_circles =
        @coordinator_private_circles
        .joins(:join_requests)
        .merge(@user.join_requests.where(status: [:pending, :accepted]))
        .select("entourages.id, entourages.title, join_requests.role, join_requests.status")
        .order("join_requests.status desc")

      @more_private_circles = @user_private_circles.to_a.count < @coordinator_private_circles.count

      if params.key?(:add_private_circle) && @user.address
        address = @user.address
        group = "ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)"
        user  = "ST_SetSRID(ST_MakePoint(#{address.longitude}, #{address.latitude}), 4326)"
        @coordinator_private_circles = @coordinator_private_circles
          .select(:id, :title)
          .select("ST_Distance(#{group}, #{user}, false) as distance")
          .select("#{group} <-> #{user}")
          .order("#{group} <-> #{user}")
      end
    end

    def edit
      @user = find_user(params[:id])
    end

    def update
      user = find_user(params[:id])

      user.assign_attributes(user_params.except(:roles))
      user.roles = updated_roles_for_user(roles: user_params[:roles], user: user)

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

      if params.dig(:user, :address).present?
        updater = UserServices::AddressService.new(user: user, params: address_params)
        updater.update do |on|
          on.failure { raise "Could not update address" }
        end
      end

      redirect_to community_admin_user_path(user)
    rescue => e
      if e.is_a?(ActiveRecord::RecordInvalid)
        message = user.errors.full_messages.to_sentence
      else
        Raven.capture_exception(e)
        message = e.message
      end

      flash[:error] = "Erreur : #{message}"
      redirect_to edit_community_admin_user_path(user)
    end

    def update_group_role
      group, user = find_group_and_user

      if group.group_type == 'neighborhood' &&
         params[:role] == 'member' &&
         user == current_user &&
         !user.roles.include?(:admin)
        return redirect_to community_admin_user_path(user),
                           alert: "Vous ne pouvez pas vous retirer vous-même le rôle d'animateur."
      end

      join_request = user.join_requests.accepted.find_by!(
        joinable_id: params[:group_id]
      )

      join_request.update!(role: params[:role])

      if group.group_type == 'neighborhood'
        CommunityAdminService.adjust_coordinator_role(user)
      end

      redirect_to request.referrer || community_admin_user_path(user)
    end

    def add_to_group
      group, user = find_group_and_user

      CommunityAdminService.add_to_group(user: user, group: group, role: params[:role])

      if params[:redirect] == 'group'
        redirect_to community_admin_group_path(group)
      else
        redirect_to community_admin_user_path(user)
      end
    end

    def remove_from_group
      group, user = find_group_and_user

      join_request = user.join_requests.find_by!(
        joinable_id: group.id
      )

      if group.group_type == 'neighborhood' &&
         join_request.role == 'coordinator' &&
         user == current_user &&
         !current_user.roles.include?(:admin)
        return redirect_to community_admin_user_path(user),
                           alert: "Vous ne pouvez pas vous retirer vous-même d'un voisinage de quartier dont vous êtes animateur."
      end

      if group.group_type == 'neighborhood' &&
         !(user.roles.include?(:admin) || current_user.roles.include?(:admin)) &&
         user.entourage_participations.where(group_type: :neighborhood).merge(JoinRequest.accepted).count == 1
        return redirect_to community_admin_user_path(user),
                           alert: "Vous ne pouvez pas retirer une personne de son seul voisinage de quartier."
      end

      if !current_user.roles.include?(:admin) &&
         group.join_requests.accepted.count == 1
        group_name = t "community.#{community.slug}.group_types.#{group.group_type}", default: "groupe"
        return redirect_to community_admin_group_path(group),
                           alert: "Vous devez conserver au moins un membre dans le #{group_name}."
      end

      join_request.destroy

      if group.group_type == 'neighborhood' && join_request.role == 'coordinator'
        should_be_coordinator = user.join_requests.accepted.where(role: :coordinator).exists?
        is_coordinator = user.roles.include?(:coordinator)
        if  !should_be_coordinator && is_coordinator
          user.roles.delete :coordinator
        end
        user.save! if user.changed?
      end

      if params[:redirect] == 'group'
        redirect_to community_admin_group_path(group)
      else
        redirect_to community_admin_user_path(user)
      end
    end

    def archive
      user = find_user(params[:id])
      UserServices::DeleteUserService.new(user: user).delete
      redirect_to community_admin_user_path(user)
    end

    def unarchive
      user = find_user(params[:id])
      UserServices::DeleteUserService.new(user: user).undelete
      redirect_to community_admin_user_path(user)
    end

    def new
      @user = User.new
    end

    def create
      builder = UserServices::PublicUserBuilder.new(params: user_params, community: community)
      user = nil
      builder.create(send_sms: true) do |on|
        on.success { |new_user| user = new_user }
      end
      raise :error unless user

      user.roles = updated_roles_for_user(roles: user_params[:roles], user: user)
      user.save

      groups = []
      for_group = nil

      if params.key?(:for_group)
        for_group = find_group(params[:for_group])
        groups.push [
          for_group,
          params[:for_role]
        ]
      end

      if !current_user.roles.include?(:admin) &&
         groups.none? { |g, _| g.group_type == 'neighborhood' }

        groups.push [
          CommunityAdminService.coordinator_neighborhoods(current_user).first,
          nil
        ]
      end

      groups.each do |group, role|
        CommunityAdminService.add_to_group(user: user, group: group, role: role)
      end

      if for_group
        redirect_to community_admin_group_path(for_group)
      else
        redirect_to community_admin_user_path(user, post_create: 1)
      end
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

    def address_params
      params.require(:user).require(:address).permit(
        :place_name,
        :latitude, :longitude,
        :google_place_id
      )
    end

    def find_group group_id
      group = Entourage.find(group_id)

      scope =
        case group.group_type
        when 'neighborhood'
          CommunityAdminService.coordinator_neighborhoods(current_user)
        when 'private_circle'
          CommunityAdminService.coordinator_private_circles(current_user)
        else
          raise
        end

      raise unless scope.where(id: group_id).exists?

      group
    end

    def find_group_and_user
      group = find_group(params[:group_id])
      user = find_user(params[:user_id])
      [group, user]
    end

    private

    def updated_roles_for_user roles:, user:
      modifiable_roles = CommunityAdminService.modifiable_roles(by: current_user, of: user)
      persisted_roles = user.roles - modifiable_roles
      submitted_roles = (roles || []).map(&:to_sym)
      (submitted_roles & modifiable_roles) + persisted_roles
    end
  end
end

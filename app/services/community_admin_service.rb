module CommunityAdminService
  def self.coordinators(community)
    User.where(community: community)
        .where("roles ?| array['coordinator', 'admin']")
  end

  def self.coordinator?(user)
    (user.roles & [:coordinator, :admin]).any?
  end

  def self.after_sign_in_url(user:, continue: nil)
    if continue.present?
      continue
    else
      :community_admin_dashboard
    end
  end

  def self.coordinator_neighborhoods(user)
    if user.roles.include?(:admin)
      user.community.entourages
        .where(group_type: :neighborhood)
    else
      Entourage
        .where(group_type: :neighborhood)
        .joins(%{
          join
            join_requests as coordinator_join_requests
          on
            coordinator_join_requests.joinable_id = entourages.id and
            coordinator_join_requests.joinable_type = 'Entourage' and
            coordinator_join_requests.status = 'accepted' and
            coordinator_join_requests.role = 'coordinator' and
            coordinator_join_requests.user_id = #{user.id}
        })
    end
  end

  def self.coordinator_neighborhoods_and_users(user)
    neighborhoods = coordinator_neighborhoods(user)
    users =
      if user.roles.include?(:admin)
        user.community.users
      else
        CommunityAdminService.users(neighborhoods)
      end
    [neighborhoods, users]
  end

  def self.coordinator_users_filtered(user, neighborhoods, has_private_circle: nil, neighborhood_status: nil, archived: false)
    neighborhood_ids = Array(neighborhoods).map { |n| n.is_a?(Entourage) ? n.id : n }

    if neighborhood_ids.none?
      return User.none
    end

    scope = User
      .where(community: user.community)
      .joins(%{
        left join
          join_requests
        on
          join_requests.joinable_type = 'Entourage' and
          join_requests.user_id = users.id
      })
      .joins(%{
        left join
          entourages neighborhoods
        on
          neighborhoods.group_type = 'neighborhood' and
          neighborhoods.id = join_requests.joinable_id
      })
      .group(:id)

    scope = scope.where(deleted: archived)

    clauses = []

    if neighborhood_ids.delete(:none).present?
      clauses.push "cardinality(array_remove(array_agg(neighborhoods.id), null)) = 0"
    end
    if neighborhood_ids.any?
      clauses.push "array_agg(neighborhoods.id) && ARRAY[%s]" %
        neighborhood_ids.map { |id| ApplicationRecord.connection.quote(id) }.join(',')
    end

    clauses = [clauses.join(" or ")]

    scope = scope.joins(%{
      left join
        entourages private_circles
      on
        private_circles.group_type = 'private_circle' and
        private_circles.id = join_requests.joinable_id
    })

    if has_private_circle != nil
      condition = has_private_circle ? "> 0" : "= 0"
      clauses.push "cardinality(array_remove(array_agg(private_circles.id), null)) #{condition}"
    end

    case neighborhood_status
    when nil
      scope = scope.where("neighborhoods is null or join_requests.status in ('pending', 'accepted')")
    else
      scope = scope.where("neighborhoods is null or join_requests.status = ?", neighborhood_status)
    end

    scope.having(clauses.map { |c| "(#{c})" }.join(" and "))
  end

  def self.users(neighborhoods)
    neighborhood_ids = Array(neighborhoods).map { |n| n.is_a?(Entourage) ? n.id : n }
    User
      .joins(:join_requests)
      .merge(
        JoinRequest
        .where(status: [:pending, :accepted])
        .where(joinable_type: :Entourage, joinable_id: neighborhood_ids)
      )
      .uniq
  end

  def self.coordinator_private_circles(user, has_pending_field: false)
    if user.roles.include?(:admin)
      scope = user.community.entourages
        .where(group_type: :private_circle)

      if has_pending_field
        scope = scope.joins(%{
          left join
            join_requests as member_to_private_circle
          on
            member_to_private_circle.joinable_id = entourages.id and
            member_to_private_circle.joinable_type = 'Entourage' and
            member_to_private_circle.status = 'pending' and
            member_to_private_circle.role in ('visitor', 'visited')
        })
        .uniq
      end
    else
      neighborhood_ids = coordinator_neighborhoods(user).pluck(:id)
      scope = Entourage
        .where(group_type: :private_circle)
        .joins(%{
          join
            join_requests as member_to_private_circle
          on
            member_to_private_circle.joinable_id = entourages.id and
            member_to_private_circle.joinable_type = 'Entourage' and
            member_to_private_circle.status in ('pending', 'accepted') and
            member_to_private_circle.role in ('visitor', 'visited')
        })
        .joins(%{
          join
            join_requests as member_to_neighborhood
          on
            member_to_neighborhood.user_id = member_to_private_circle.user_id and
            member_to_neighborhood.joinable_type = 'Entourage' and
            member_to_neighborhood.status = 'accepted'
        })
        .where(member_to_neighborhood: {joinable_id: neighborhood_ids})
        .uniq
    end

    if has_pending_field
      has_pending = %{
        count(
          case when member_to_private_circle.status = 'pending' then 1 end
        ) > 0
      }

      scope = scope
        .group(:id)
        .select("#{has_pending} as has_pending")
        .order("#{has_pending} desc")
    end

    scope
  end

  def self.coordinator_outings(user)
    if user.roles.include?(:admin)
      scope = user.community.entourages
        .where(group_type: :outing)
    else
      neighborhood_ids = coordinator_neighborhoods(user).pluck(:id)
      scope = Entourage
        .where(group_type: :outing)
        .joins(%{
          join
            join_requests as member_to_outing
          on
            member_to_outing.joinable_id = entourages.id and
            member_to_outing.joinable_type = 'Entourage' and
            member_to_outing.status = 'accepted' and
            member_to_outing.role = 'organizer'
        })
        .joins(%{
          join
            join_requests as member_to_neighborhood
          on
            member_to_neighborhood.user_id = member_to_outing.user_id and
            member_to_neighborhood.joinable_type = 'Entourage' and
            member_to_neighborhood.status = 'accepted'
        })
        .where(member_to_neighborhood: {joinable_id: neighborhood_ids})
        .uniq
    end

    scope
  end

  def self.role_color(community, role)
    case role
    when :coordinator then 'success'
    when :admin then 'dark'
    when :not_validated then 'warning'
    when :visitor, :member then nil
    else 'info'
    end
  end

  def self.readable_roles(user)
    base = [:not_validated, :ethics_charter_signed, :visitor, :visited, :coordinator]

    if user.roles.include?(:admin)
      base + [:admin]
    else
      base
    end
  end

  def self.modifiable_roles(by:, of:)
    base = readable_roles(by)

    if by == of && by.roles.include?(:admin)
      base - [:admin]
    elsif by == of && by.roles.include?(:coordinator)
      base - [:coordinator]
    else
      base
    end
  end

  def self.add_to_group(user:, group:, role: nil)
    join_request = JoinRequest.find_or_initialize_by(
      user_id: user.id,
      joinable: group
    )

    role ||=
      case group.group_type.to_sym
      when :neighborhood
        :member
      when :private_circle
        user.roles.include?(:visited) ? :visited : :visitor
      end

    join_request.status = :accepted
    join_request.role ||= role

    join_request.save! if join_request.new_record? || join_request.changed?

    adjust_coordinator_role(user) if group.group_type == 'neighborhood'
  end

  def self.adjust_coordinator_role(user)
    should_be_coordinator = user.join_requests.accepted.where(role: :coordinator).exists?
    is_coordinator = user.roles.include?(:coordinator)
    if should_be_coordinator && !is_coordinator
      user.roles.push :coordinator
    elsif !should_be_coordinator && is_coordinator
      user.roles.delete :coordinator
    end
    user.save! if user.changed?
  end
end

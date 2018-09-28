module CommunityAdminService
  def self.coordinators(community)
    User.where(community: community)
        .where("roles ?| array['coordinator', 'admin']")
  end

  def self.after_sign_in_url(user:, continue: nil)
    if continue.present?
      continue
    else
      :community_admin_users
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

  def self.coordinator_users_filtered(user, neighborhoods)
    unless user.roles.include?(:admin) && neighborhoods.include?(:none)
      return users(neighborhoods)
    end

    neighborhood_ids = Array(neighborhoods).map { |n| n.is_a?(Entourage) ? n.id : n }

    scope = User
      .where(community: user.community)
      .joins(%{
        left join
          join_requests
        on
          join_requests.joinable_type = 'Entourage' and
          join_requests.status = 'accepted' and
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

    clauses = []
    if neighborhood_ids.delete(:none).present?
      clauses.push "cardinality(array_remove(array_agg(neighborhoods.id), null)) = 0"
    end
    if neighborhood_ids.any?
      clauses.push "array_agg(neighborhoods.id) && ARRAY[%s]" %
        neighborhood_ids.map { |id| ActiveRecord::Base.connection.quote(id) }.join(',')
    end
    scope.having(clauses.join(" or "))
  end

  def self.users(neighborhoods)
    neighborhood_ids = Array(neighborhoods).map { |n| n.is_a?(Entourage) ? n.id : n }
    User
      .joins(:join_requests)
      .merge(
        JoinRequest
        .accepted
        .where(joinable_type: :Entourage, joinable_id: neighborhood_ids)
      )
      .uniq
  end

  def self.coordinator_private_circles(user)
    if user.roles.include?(:admin)
      user.community.entourages
        .where(group_type: :private_circle)
    else
      neighborhood_ids = coordinator_neighborhoods(user).pluck(:id)
      Entourage
        .where(group_type: :private_circle)
        .joins(%{
          join
            join_requests as member_to_private_circle
          on
            member_to_private_circle.joinable_id = entourages.id and
            member_to_private_circle.joinable_type = 'Entourage' and
            member_to_private_circle.status = 'accepted' and
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
  end

  def self.role_color(community, role)
    case role
    when :coordinator then 'success'
    when :admin then 'dark'
    when :visitor, :member then nil
    else 'info'
    end
  end

  def self.readable_roles(user)
    if user.roles.include?(:admin)
      [:visitor, :visited, :coordinator, :admin]
    else
      [:visitor, :visited, :coordinator]
    end
  end

  def self.modifiable_roles(by:, of:)
    base = readable_roles(by) - [:coordinator]

    if by == of && by.roles.include?(:admin)
      base - [:admin]
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

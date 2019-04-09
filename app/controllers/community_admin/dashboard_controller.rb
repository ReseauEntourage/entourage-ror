module CommunityAdmin
  class DashboardController < BaseController
    def index
      neighborhoods = CommunityAdminService.coordinator_neighborhoods(current_user)

      neighborhood_ids = neighborhoods.pluck(:id)
      neighborhood_ids.push(:none) if current_user.roles.include?(:admin)

      @not_validated_count =
        CommunityAdminService.coordinator_users_filtered(
          current_user, neighborhood_ids)
        .where("roles ? 'not_validated'")
        .pluck(1).count

      without_private_circle =
        CommunityAdminService.coordinator_users_filtered(
          current_user, neighborhood_ids,
          has_private_circle: false)

      @visitors_without_visited_count =
        without_private_circle
        .where("roles ? 'visitor'")
        .pluck(1).count

      @visited_without_visitor_count =
        without_private_circle
        .where("roles ? 'visited'")
        .pluck(1).count

      @neighborhoods_requests_count =
        neighborhoods
        .joins(%{
          join
            join_requests member_join_requests
          on
            member_join_requests.joinable_id = entourages.id and
            member_join_requests.joinable_type = 'Entourage' and
            member_join_requests.status = 'pending'
        })
        .count

      @private_circles_requests_count =
        CommunityAdminService.coordinator_private_circles(
          current_user, has_pending_field: true)
        .unscope(:group, :select, :order)
        .where("member_to_private_circle.status = 'pending'")
        .count

      if current_user.roles.include?(:admin)
        @without_neighborhood =
          CommunityAdminService.coordinator_users_filtered(
            current_user, :none)
          .pluck(1).count
      end

      @upcoming_outings =
        CommunityAdminService.coordinator_outings(current_user)
          .where("metadata->>'starts_at' between ? and ?",
                 0.day.ago.midnight, 1.week.from_now.end_of_day)
          .select(:title, :metadata, "metadata->>'starts_at'") # required for select distinct + order
          .order("metadata->>'starts_at'")
          .to_a
    end
  end
end

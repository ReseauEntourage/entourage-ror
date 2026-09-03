module Admin
  class ModeratorWorkloadsController < Admin::BaseController
    def index
      moderators = current_user.community.users.moderators.validated.order(:first_name)

      @rows = moderators.map do |moderator|
        assigned = ModerationServices.assigned_open_entourages(moderator)

        unmoderated = assigned.where(%(
          entourage_moderations.moderated_at is null and entourages.created_at >= '2018-01-01'
        ))

        {
          moderator: moderator,
          open_count: assigned.count,
          unmoderated_count: unmoderated.count,
        }
      end.sort_by { |row| -row[:open_count] }

      @unassigned_count = Entourage
        .where(group_type: ['action', 'outing'], status: ModerationServices::OPEN_ENTOURAGE_STATUSES)
        .with_moderation
        .moderator_search('none')
        .count
    end
  end
end

module Admin
  class ModeratorWorkloadsController < Admin::BaseController
    def index
      moderators = current_user.community.users.moderators.validated.order(:first_name)

      @rows = ModerationServices.workload_rows(moderators)
      @unassigned_count = ModerationServices.unassigned_open_entourages_count
    end
  end
end

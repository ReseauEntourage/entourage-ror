module Admin
  class DashboardController < Admin::BaseController
    RECENT_WINDOW = 2.days

    def index
      @new_users_count = current_user.community.users.where('users.created_at >= ?', RECENT_WINDOW.ago).count

      open_entourages = Entourage.where(group_type: ['action', 'outing'], status: ModerationServices::OPEN_ENTOURAGE_STATUSES).with_moderation
      @pending_moderation_count = ModerationServices.unmoderated_entourages(open_entourages).count
      @unassigned_count = ModerationServices.unassigned_open_entourages_count

      @recent_blocks = UserHistory.blocked.where('user_histories.created_at >= ?', RECENT_WINDOW.ago).includes(:user, :updater).limit(10)

      @my_queue_count = ModerationServices.open_queue_count(current_user) if current_user.roles.include?(:moderator)

      moderators = current_user.community.users.moderators.validated
      @busiest_moderators = ModerationServices.workload_rows(moderators).first(5)
    end
  end
end

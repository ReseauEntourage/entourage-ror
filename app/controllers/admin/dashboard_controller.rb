module Admin
  class DashboardController < Admin::BaseController
    RECENT_WINDOW = 2.days
    WINDOWS = [1, 7, 30].freeze

    def index
      @departments = ModerationServices.departments_for(current_user)
      @zone = params[:zone] == 'all' || @departments.empty? ? :all : :mine

      @activity = WINDOWS.map do |days|
        since = days.days.ago
        entourages_in_window = zone_scoped_entourages.where('entourages.created_at >= ?', since)

        {
          days: days,
          new_users: zone_scoped_users.where('users.created_at >= ?', since).count,
          new_entourages: entourages_in_window.count,
          new_unmoderated_entourages: ModerationServices.unmoderated_entourages(entourages_in_window.with_moderation).count,
          new_messages: ChatMessage
            .where(messageable_type: 'Entourage', messageable_id: zone_scoped_entourages.select(:id))
            .where('chat_messages.created_at >= ?', since)
            .count,
        }
      end

      @photo_queue_count = User.validated.where('avatar_key IS NOT NULL').count
      @pending_moderation_count = ModerationServices.unmoderated_entourages(
        Entourage.where(group_type: ['action', 'outing'], status: ModerationServices::OPEN_ENTOURAGE_STATUSES).with_moderation
      ).count
      @unassigned_count = ModerationServices.unassigned_open_entourages_count

      @recent_blocks = UserHistory.blocked.where('user_histories.created_at >= ?', RECENT_WINDOW.ago).includes(:user, :updater).limit(10)

      @my_queue_count = ModerationServices.open_queue_count(current_user) if current_user.roles.include?(:moderator)

      moderators = current_user.community.users.moderators.validated
      @busiest_moderators = ModerationServices.workload_rows(moderators).first(5)
    end

    private

    def zone_scoped_users
      users = current_user.community.users
      return users if @zone == :all

      users.in_specific_areas(@departments)
    end

    def zone_scoped_entourages
      entourages = Entourage.where(group_type: ['action', 'outing'])
      return entourages if @zone == :all

      entourages.where(country: 'FR').where('left(postal_code, 2) in (?)', @departments)
    end
  end
end

module Admin
  class ActivityFeedController < Admin::BaseController
    WINDOW = 2.days

    def index
      @window = WINDOW

      users = current_user.community.users
        .where('users.created_at >= ?', WINDOW.ago)
        .order(created_at: :desc)
        .limit(50)
        .map { |record| { type: :user, created_at: record.created_at, record: record } }

      entourages = Entourage
        .where(group_type: ['action', 'outing'])
        .where('entourages.created_at >= ?', WINDOW.ago)
        .order(created_at: :desc)
        .limit(50)
        .map { |record| { type: :entourage, created_at: record.created_at, record: record } }

      neighborhoods = Neighborhood
        .where('neighborhoods.created_at >= ?', WINDOW.ago)
        .order(created_at: :desc)
        .limit(50)
        .map { |record| { type: :neighborhood, created_at: record.created_at, record: record } }

      @items = (users + entourages + neighborhoods).sort_by { |item| item[:created_at] }.reverse
    end
  end
end

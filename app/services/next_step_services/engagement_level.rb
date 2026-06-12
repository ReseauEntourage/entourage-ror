module NextStepServices
  class EngagementLevel
    def initialize(user:)
      @user = user
    end

    def call
      return :dormant if dormant?

      count = accepted_join_requests_count

      if count >= 8 && recurring_activity?
        3
      elsif count >= 3
        2
      elsif count >= 1
        1
      else
        0
      end
    end

    private

    def dormant?
      @user.last_sign_in_at.present? && @user.last_sign_in_at < 30.days.ago
    end

    def accepted_join_requests_count
      JoinRequest.accepted.where(user: @user).count
    end

    def recurring_activity?
      recent_months = JoinRequest.accepted
        .where(user: @user)
        .where('created_at > ?', 60.days.ago)
        .pluck(:created_at)
        .map { |t| t.strftime('%Y-%m') }
        .uniq

      recent_months.size >= 2
    end
  end
end

module NextStepServices
  class PushEligibility
    def initialize(user:)
      @user = user
    end

    def eligible?
      return false unless has_device_token?
      return false unless within_allowed_hours?
      return false if recently_signed_in?
      return false if recently_pushed?
      return false if push_paused?
      return false if isolated_person_without_opt_in?
      return false if neighbor_with_opt_out?

      true
    end

    private

    def has_device_token?
      UserServices::UserApplications.new(user: @user).app_tokens.any?
    end

    def within_allowed_hours?
      hour = Time.zone.now.hour
      hour >= 8 && hour < 22
    end

    def recently_signed_in?
      @user.last_sign_in_at.present? && @user.last_sign_in_at > 30.minutes.ago
    end

    def recently_pushed?
      last_push_at = @user.options&.dig('last_push_at')
      return false if last_push_at.nil?

      Time.zone.parse(last_push_at) > 24.hours.ago
    end

    def push_paused?
      paused_until = @user.options&.dig('push_paused_until')
      return false if paused_until.nil?

      Time.zone.parse(paused_until) > Time.zone.now
    end

    def isolated_person_without_opt_in?
      @user.goal == 'ask_for_help' && @user.options&.dig('push_enabled') != true
    end

    def neighbor_with_opt_out?
      @user.goal != 'ask_for_help' && @user.options&.dig('push_enabled') == false
    end
  end
end

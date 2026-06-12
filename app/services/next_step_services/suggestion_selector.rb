module NextStepServices
  class SuggestionSelector
    def initialize(user:)
      @user = user
    end

    def call
      existing = existing_active_step
      return existing if existing

      suggestion = select_suggestion
      return nil if suggestion.nil?

      UserNextStep.create!(
        user: @user,
        next_step_suggestion: suggestion,
        status: 'active',
        shown_at: Time.zone.now,
        expires_at: suggestion.valid_for_days.days.from_now
      )
    end

    private

    def existing_active_step
      step = UserNextStep.active_status.where(user: @user).order(created_at: :desc).first
      return nil if step.nil?
      return nil if step.expired?
      step
    end

    def select_suggestion
      level = NextStepServices::EngagementLevel.new(user: @user).call
      dismissed_types = recently_dismissed_types

      if level == :dormant
        suggestion = NextStepSuggestion.active
          .where(suggestion_type: 'reengagement')
          .where.not(suggestion_type: dismissed_types)
          .order(priority: :desc)
          .first

        suggestion ||= NextStepSuggestion.active
          .where(suggestion_type: 'fallback')
          .order(priority: :desc)
          .first

        return suggestion
      end

      profile = @user.goal.presence || 'all'

      suggestion = NextStepSuggestion.active
        .for_profile(profile)
        .for_level(level)
        .where.not(suggestion_type: dismissed_types)
        .order(priority: :desc)
        .first

      suggestion ||= NextStepSuggestion.active
        .where(suggestion_type: 'fallback')
        .order(priority: :desc)
        .first

      suggestion
    end

    def recently_dismissed_types
      UserNextStep
        .recent_dismissals
        .where(user: @user)
        .joins(:next_step_suggestion)
        .pluck('next_step_suggestions.suggestion_type')
        .uniq
    end
  end
end

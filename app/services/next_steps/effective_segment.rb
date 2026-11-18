module NextSteps
  # The engagement segment the engine works with: the last one computed for the
  # user (EN-9444), whatever its age, or a stand-in when there is none.
  #
  # - nil segment, no engagement ever: a new user, treated as Silencieux / À activer
  # - nil segment, an engagement in the past: a user back after more than 30
  #   days, treated as Silencieux / Dormant (same rule as the Dormant
  #   sub-segment of EngagementSegmentComputation: any row in
  #   denorm_daily_engagements_with_type)
  # - team users are never classified by EN-9444: treated as Contributeur
  class EffectiveSegment
    SILENCIEUX = 'Silencieux'.freeze
    A_ACTIVER = 'À activer'.freeze
    DORMANT = 'Dormant'.freeze
    CONTRIBUTEUR = 'Contributeur'.freeze

    attr_reader :segment, :sub_segment, :source

    def self.for user
      new(user)
    end

    def initialize user
      @segment, @sub_segment, @source = resolve(user)
    end

    # "Silencieux / Dormant", "Curieux"…: the key of NextSteps::Selector::SEGMENT_TYPES
    def key
      [segment, sub_segment].compact.join(' / ')
    end

    private

    def resolve user
      return [CONTRIBUTEUR, nil, 'team'] if user.team?

      user_segment = user.user_segment

      if user_segment&.engagement_segment.present?
        [user_segment.engagement_segment, user_segment.engagement_sub_segment, 'computed']
      elsif DenormDailyEngagementsWithType.where(user_id: user.id).exists?
        [SILENCIEUX, DORMANT, 'assumed_returning']
      else
        [SILENCIEUX, A_ACTIVER, 'assumed_new']
      end
    end
  end
end

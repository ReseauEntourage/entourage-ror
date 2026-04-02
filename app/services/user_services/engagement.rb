module UserServices
  module Engagement
    extend ActiveSupport::Concern

    SILENT = "Silencieux"
    PASSIVE = "Passif"
    OBSERVE = "Observateur"
    ENGAGE = "Engagé"
    SUPER_ENGAGE = "Super-engagé"

    included do
      has_one :engagement_level

      has_many :denorm_daily_engagements, foreign_key: :user_id

      scope :engaged, -> {
        joins(:engagement_level)
          .where("level_1_count > 0 OR level_2_count > 0 OR level_3_count > 0")
      }

      scope :not_engaged, -> {
        left_joins(:engagement_level)
          .where("user_id is NULL OR (level_1_count = 0 AND level_2_count = 0 AND level_3_count = 0)")
      }

      scope :engaged_after, ->(date) {
        joins(:denorm_daily_engagements_with_types)
          .where("denorm_daily_engagements_with_type.date >= ?", date)
          .select("DISTINCT ON (users.id) users.*")
      }
    end

    def engaged?
      engagement.engaged?
    end

    def badge
      engagement.badge
    end

    EngagementStruct = Struct.new(:user) do
      def initialize(user: nil)
        @user = user
      end

      def engagement_level
        @user.engagement_level
      end

      def score
        return 0 unless engagement_level

        level_1 + level_2 + level_3
      end

      def badge
        return SILENT if level_3 >= 2
        return ENGAGE if level_2 >= 2
        return OBSERVE if level_1 >= 3
        return PASSIVE if level_1 >= 1

        SILENT
      end

      def engaged?
        engagement_level.present?
      end

      def levels
        {
          1 => level_1,
          2 => level_2,
          3 => level_3
        }
      end

      def level_1
        return 0 unless engagement_level

        engagement_level.level_1_count
      end

      def level_2
        return 0 unless engagement_level

        engagement_level.level_2_count
      end

      def level_3
        return 0 unless engagement_level

        engagement_level.level_3_count
      end
    end

    def engagement
      @engagement ||= EngagementStruct.new(user: self)
    end

    # @see UserSerializer
    def ask_for_help_creation_count
      open_actions_creation.ask_for_helps.count
    end

    # @see UserSerializer
    def contribution_creation_count
      open_actions_creation.contributions.count
    end

    private
    def open_actions_creation
      Entourage.where(user: self)
        .where(group_type: :action, status: :open)
        .where('entourages.created_at > ?', 1.year.ago)
    end
  end
end

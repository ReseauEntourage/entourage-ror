module UserServices
  module Engagement
    extend ActiveSupport::Concern

    included do
      has_many :denorm_daily_engagements, foreign_key: :user_id

      scope :engaged, -> {
        joins(:denorm_daily_engagements).group(:id)
      }

      scope :not_engaged, -> {
        left_joins(:denorm_daily_engagements)
        .where(denorm_daily_engagements: { id: nil })
        .group(:id)
      }
    end

    EngagementStruct = Struct.new(:user) do
      def initialize(user: nil)
        @user = user
      end

      def stacked_by group = :month
        fill_in_with_all_dates [
          {
            name: I18n.t("charts.users.member_outings"),
            data: outings_join_requests_by(group).map { |date, count| [date.to_date.to_s, count] }
          },
          {
            name: I18n.t("charts.users.member_neighborhoods"),
            data: neighborhoods_join_requests_by(group).map { |date, count| [date.to_date.to_s, count] }
          },
          {
            name: I18n.t("charts.users.reactions"),
            data: reactions_by(group).map { |date, count| [date.to_date.to_s, count] }
          },
          {
            name: I18n.t("charts.users.public_chat_messages"),
            data: public_chat_messages_by(group).map { |date, count| [date.to_date.to_s, count] }
          },
          {
            name: I18n.t("charts.users.private_chat_messages"),
            data: private_chat_messages_by(group).map { |date, count| [date.to_date.to_s, count] }
          }
        ]
      end

      # hack to force rendering with ordered dates
      def fill_in_with_all_dates charts
        all_dates = charts.flat_map { |category| category[:data].map { |entry| entry[0] } }.uniq.sort

        complete_data = charts.map do |category|
          complete_dates = all_dates.map do |date|
            found_entry = category[:data].find { |entry| entry[0] == date }
            [date, found_entry ? found_entry[1] : 0]
          end

          { name: category[:name], data: complete_dates }
        end
      end

      # memberships
      def outings_join_requests
        @outings_join_requests ||= JoinRequest
          .where(joinable_type: :Entourage, user_id: @user.id)
          .where("joinable_id in (select id from entourages where group_type = 'outing')")
      end

      def outings_join_requests_by group
        outings_join_requests
          .group("DATE_TRUNC('#{group}', created_at)")
          .order(Arel.sql("DATE_TRUNC('#{group}', created_at)"))
          .count
      end

      def neighborhoods_join_requests
        @neighborhoods_join_requests ||= JoinRequest.where(joinable_type: :Neighborhood, user_id: @user.id)
      end

      def neighborhoods_join_requests_by group
        neighborhoods_join_requests
          .group("DATE_TRUNC('#{group}', created_at)")
          .order(Arel.sql("DATE_TRUNC('#{group}', created_at)"))
          .count
      end

      # reactions
      def reactions
        @reactions ||= UserReaction.where(user_id: @user.id)
      end

      def reactions_by group
        reactions
          .group("DATE_TRUNC('#{group}', created_at)")
          .order(Arel.sql("DATE_TRUNC('#{group}', created_at)"))
          .count
      end

      # chat_messages
      def public_chat_messages
        @public_chat_messages ||= ChatMessage
          .where(user_id: @user.id, message_type: :text)
          .where("messageable_type = 'Neighborhood' or (messageable_id in (select id from entourages where group_type = 'outing'))")
      end

      def public_chat_messages_by group
        public_chat_messages
          .group("DATE_TRUNC('#{group}', created_at)")
          .order(Arel.sql("DATE_TRUNC('#{group}', created_at)"))
          .count
      end

      def private_chat_messages
        @private_chat_messages ||= ChatMessage
          .where(user_id: @user.id, message_type: :text, messageable_type: :Entourage)
          .where("messageable_id in (select id from entourages where group_type = 'conversation')")
      end

      def private_chat_messages_by group
        private_chat_messages
          .group("DATE_TRUNC('#{group}', created_at)")
          .order(Arel.sql("DATE_TRUNC('#{group}', created_at)"))
          .count
      end
    end

    def engagement
      @engagement ||= EngagementStruct.new(user: self)
    end

    def engaged?
      DenormDailyEngagement.find_by(user: self).present?
    end

    def ask_for_help_creation_count
      open_actions_creation.ask_for_helps.count
    end

    def contribution_creation_count
      open_actions_creation.contributions.count
    end

    private
    def open_actions_creation
      Entourage.where(user: self)
        .where(group_type: :action, status: :open)
        .where("entourages.created_at > ?", 1.year.ago)
    end
  end
end

module UserServices
  module Engagement
    extend ActiveSupport::Concern

    included do
      has_one :user_denorm

      scope :engaged, -> {
        joins(:user_denorm).where(%{
          last_created_action_id is not null or
          last_join_request_id is not null or
          last_private_chat_message_id is not null or
          last_group_chat_message_id is not null
        })
      }

      scope :not_engaged, -> {
        joins('left join user_denorms on user_denorms.user_id = users.id').where(%{
          user_denorms.id is null or (
            last_created_action_id is null and
            last_join_request_id is null and
            last_private_chat_message_id is null and
            last_group_chat_message_id is null
          )
        })
      }
    end

    EngagementStruct = Struct.new(:user) do
      def initialize(user: nil)
        @user = user
      end

      def stacked_by group = :month
        [
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
        @public_chat_messages ||= ChatMessage.where(user_id: @user.id, message_type: :text)
      end

      def public_chat_messages_by group
        public_chat_messages
          .group("DATE_TRUNC('#{group}', created_at)")
          .order(Arel.sql("DATE_TRUNC('#{group}', created_at)"))
          .count
      end

      def private_chat_messages
        @private_chat_messages ||= ChatMessage.where(user_id: @user.id, message_type: :text, messageable_type: :Entourage)
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
      return false unless user_denorm

      user_denorm.last_created_action_id.present? ||
        user_denorm.last_join_request_id.present? ||
        user_denorm.last_private_chat_message_id.present? ||
        user_denorm.last_group_chat_message_id.present?
    end

    def last_created_action_id; user_denorm&.last_created_action_id; end
    def last_join_request_id; user_denorm&.last_join_request_id; end
    def last_private_chat_message_id; user_denorm&.last_private_chat_message_id; end
    def last_group_chat_message_id; user_denorm&.last_group_chat_message_id; end

    def last_created_action
      return nil unless last_created_action_id

      Entourage.find_by(id: last_created_action_id)
    end

    def last_join_request
      return nil unless last_join_request_id

      JoinRequest.find_by(id: last_join_request_id)
    end

    def last_join_action
      return nil unless last_join_request_id

      Entourage.find_by(id: join_request.joinable_id)
    end

    def last_private_chat_message
      return nil unless last_private_chat_message_id

      ChatMessage.find_by(id: last_private_chat_message_id)
    end

    def last_group_chat_message
      return nil unless last_group_chat_message_id

      ChatMessage.find_by(id: last_group_chat_message_id)
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

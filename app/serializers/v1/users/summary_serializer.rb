module V1
  module Users
    class SummarySerializer < BasicSerializer
      attributes :id,
        :display_name,
        :avatar_url,
        :meetings_count,
        :chat_messages_count,
        :outing_participations_count,
        :neighborhood_participations_count,
        :recommandations,
        :congratulations,
        :moderator

      def meetings_count
        return 0 unless user = scope[:user]

        past_outing_memberships(user) + action_creations(user)
      end

      def chat_messages_count
        object.chat_messages.count
      end

      def outing_participations_count
        object.outing_memberships.count
      end

      def neighborhood_participations_count
        object.neighborhood_memberships.count
      end

      def recommandations
        object.user_recommandations.active.order(:fragment).map do |recommandation|
          V1::UserRecommandationSerializer.new(recommandation).as_json
        end
      end

      def congratulations
        object.user_recommandations.to_be_congratulated.order(completed_at: :desc).map do |recommandation|
          recommandation.update_column(:congrats_at, Time.now)

          V1::UserRecommandationSerializer.new(recommandation).as_json
        end
      end

      def moderator
        return Hash.new unless moderator = ModerationServices.moderator_for_user(scope[:user])

        {
          id: moderator.id,
          display_name: UserPresenter.new(user: moderator).display_name,
          avatar_url: UserServices::Avatar.new(user: moderator).thumbnail_url
        }
      end

      private

      def past_outing_memberships user
        user.outing_memberships.where(id: Outing.active.past)
      end

      def action_creations user
        Entourage.action.active.where(user: user)
      end
    end
  end
end

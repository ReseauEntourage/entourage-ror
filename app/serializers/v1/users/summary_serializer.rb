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
        :recommandations

      def meetings_count
        0
      end

      def chat_messages_count
        object.chat_messages.count
      end

      def neighborhood_participations_count
        object.join_requests.where(joinable_type: :Neighborhood).count
      end

      def recommandations
        UserServices::Recommandations.new(object).find.map do |recommandation|
          V1::RecommandationSerializer.new(recommandation).as_json
        end
      end
    end
  end
end

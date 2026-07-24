module Preloaders
  module Entourage
    # @see V1::ConversationSerializer#current_join_request, V1::EntourageSerializer#current_join_request
    def self.preload_current_join_request(entourages, user:)
      entourage_ids = entourages.map(&:id)

      return if entourage_ids.empty?

      join_requests_by_entourage_id = user.join_requests
        .where(joinable_type: 'Entourage', joinable_id: entourage_ids)
        .index_by(&:joinable_id)

      entourages.each do |entourage|
        entourage.current_join_request = join_requests_by_entourage_id[entourage.id]
      end
    end
  end
end

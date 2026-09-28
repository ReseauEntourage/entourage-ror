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

    # blocages entre `user` et les participants de ses conversations : une requête pour toute la
    # page, au lieu d'une par conversation (@see V1::Entourages::Blockers#blockers)
    def self.preload_user_blocks(entourages, user:)
      conversations = entourages.select(&:conversation?)
      return if conversations.empty?
      return unless user.is_a?(::User)

      user_blocks = ::UserBlockedUser.where(user_id: user.id).or(::UserBlockedUser.where(blocked_user_id: user.id)).pluck(:user_id, :blocked_user_id)

      conversations.each do |conversation|
        (conversation.preloaded_user_blocks ||= {})[user.id] = user_blocks
      end
    end

    # partenaire des auteurs, logo et suivi par `user` (@see V1::EntourageSerializer#author) :
    # l'auteur affiché d'une conversation est l'autre participant, pris dans accepted_members
    # quand ils sont chargés
    def self.preload_authors(entourages, user:)
      partners = entourages.flat_map do |entourage|
        members = entourage.conversation? && entourage.association(:accepted_members).loaded? ? entourage.accepted_members : []

        [entourage.user, *members].compact.map(&:partner)
      end

      Preloaders::Images.preload_partners(partners)
      Preloaders::Partner.preload_following(partners, user: user)
    end
  end
end

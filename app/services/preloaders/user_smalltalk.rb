module Preloaders
  module UserSmalltalk
    # une requête Tag pour toute la page, au lieu d'une par demande (@see UserSmalltalk#interests)
    def self.preload_interests user_smalltalks
      user_smalltalks = user_smalltalks.to_a
      return if user_smalltalks.empty?

      tags_by_id = ::Tag.where(id: user_smalltalks.flat_map { |user_smalltalk| Array(user_smalltalk.user_interest_ids) }.uniq).index_by(&:id)

      user_smalltalks.each do |user_smalltalk|
        user_smalltalk.interests = Array(user_smalltalk.user_interest_ids).filter_map { |id| tags_by_id[id] }
      end
    end
  end
end

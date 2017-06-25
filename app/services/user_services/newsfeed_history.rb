module UserServices
  class NewsfeedHistory

    NEWSFEED_KEEP=10

    class << self
      def save(user:, latitude:, longitude:)
        ActiveRecord::Base.transaction do
          user.user_newsfeeds.create(latitude: latitude, longitude: longitude)
          user.user_newsfeeds.where.not(id: latests(user)).destroy_all
        end
      end

      private
      def latests(user)
        user.user_newsfeeds.select(:id).order("created_at DESC").limit(NEWSFEED_KEEP).map(&:id)
      end
    end

  end
end

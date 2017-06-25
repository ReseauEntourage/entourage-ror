module EntourageServices
  class EntourageUserSuggestionsCalculator
    class << self
      def compute
        start = Time.now
        Rails.logger.info "start at #{start}"

        entourages.find_each do |entourage|
          users.find_each do |user|
            EntourageServices::ScoreCalculator.new(entourage: entourage, user: user).calculate
          end
        end

        stop = Time.now
        duration = stop - start
        Rails.logger.info "stop in #{duration} at #{stop}"

        SuggestionComputeHistory.create(user_number: users.count,
                                        total_user_number: User.count,
                                        entourage_number: entourages.count,
                                        total_entourage_number: Entourage.count,
                                        duration: duration)
      end

      private

      def entourages
        Entourage.where(use_suggestions: true)
      end

      def users
        User.where(use_suggestions: true)
      end

    end
  end
end

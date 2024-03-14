module EntourageServices
  class UserEntourageSuggestion
    class << self
      def perform
        ApplicationRecord.transaction do
          User.update_all(use_suggestions: false)
          User.where("last_sign_in_at > ?", 1.month.ago).update_all(use_suggestions: true)

          Entourage.update_all(use_suggestions: false)
          Entourage.where("updated_at > ?", 1.month.ago).update_all(use_suggestions: true)
        end
      end
    end
  end
end

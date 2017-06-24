module EntourageService
  class UserEntourageSuggestion
    def perform
      ActiveRecord::Base.transaction do
        User.update_all(use_suggestion: false)
        User.where("last_sign_in_at > ?", 1.month.ago).update_all(use_suggestion: true)

        Entourage.update_all(use_suggestion: false)
        Entourage.where("updated_at > ?", 1.month.ago).update_all(use_suggestion: true)
      end
    end
  end
end

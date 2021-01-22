namespace :entourage do
  task set_entourage_user_suggestion: :environment do
    EntourageServices::UserEntourageSuggestion.perform
  end
end

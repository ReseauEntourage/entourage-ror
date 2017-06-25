namespace :entourage do
  task set_entourage_user_suggestion: :environment do
    EntourageServices::UserEntourageSuggestion.perform
  end

  task set_entourage_score: :environment do
    puts "Starting set_entourage_score"
    EntourageServices::EntourageUserSuggestionsCalculator.compute
  end
end

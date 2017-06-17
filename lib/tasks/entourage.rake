namespace :data_migration do

  task set_entourage_score: :environment do
    puts "Starting set_entourage_score"
    EntourageServices::EntourageUserSuggestionsCalculator.compute
  end

end

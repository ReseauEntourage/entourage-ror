namespace :entourage do
  task set_entourage_user_suggestion: :environment do
    EntourageServices::UserEntourageSuggestion.perform
  end

  task compute_all_denorms: :environment do
    Entourage.select('id').where(group_type: [:action, :outing]).find_in_batches(batch_size: 100) do |entourages|
      entourages.each do |entourage|
        EntourageDenorm.find_or_create_by(entourage_id: entourage.id).recompute_and_save
      end
    end
  end
end

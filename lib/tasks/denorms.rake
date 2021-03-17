namespace :denorms do
  task all_entourages: :environment do
    Entourage.select('id').where(group_type: [:action, :outing]).find_in_batches(batch_size: 100) do |entourages|
      entourages.each do |entourage|
        EntourageDenorm.find_or_create_by(entourage_id: entourage.id).recompute_and_save
      end
    end
  end

  task all_users: :environment do
  end
end

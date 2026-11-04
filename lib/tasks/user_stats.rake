namespace :user_stats do
  # @see UserStat.backfill!
  # Idempotent: can be rerun at any time to resynchronize every counter.
  # Each batch is a single statement: raise ACTIVERECORD_STATEMENT_TIMEOUT or
  # lower BATCH_SIZE if batches hit the statement timeout.
  desc "Recompute every UserStat counter by batches of user ids (FROM_ID to resume, BATCH_SIZE defaults to 1000)"
  task backfill: :environment do
    batch_size = (ENV['BATCH_SIZE'] || 1000).to_i
    from_id = (ENV['FROM_ID'] || User.minimum(:id) || 0).to_i
    max_id = User.maximum(:id) || 0

    from_id.step(max_id, batch_size) do |batch_from_id|
      batch_to_id = batch_from_id + batch_size - 1
      rows = UserStat.backfill!(from_id: batch_from_id, to_id: batch_to_id)

      puts "user_stats:backfill users #{batch_from_id}..#{batch_to_id}: #{rows} rows"
    end
  end
end

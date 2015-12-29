namespace :data_migration do
  desc "run all pending migration jobs"
  task migration_jobs: :environment do
    Rake::Task["initialize_encounter_counter_cache"].invoke
  end

  desc "create simplified tour points"
  task create_simplified_tour_points: :environment do
    Tour.find_each { |t| SimplifyTourPointsJob.perform_now(t.id) }
  end

  desc "initialize encounter counter_cache"
  task initialize_encounter_counter_cache: :environment do
    Tour.update_all("encounters_count=(SELECT count(*) FROM encounters WHERE encounters.tour_id=tours.id)")
  end
end
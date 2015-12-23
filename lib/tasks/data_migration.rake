namespace :data_migration do
  desc "create simplified tour points"
  task create_simplified_tour_points: :environment do
    Tour.find_each { |t| SimplifyTourPointsJob.perform_now(t.id) }
  end
end
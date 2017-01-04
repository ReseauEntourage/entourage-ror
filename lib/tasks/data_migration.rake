namespace :data_migration do
  desc "cache recent tour points"
  task cache_tour_points: :environment do
    Tour.where("created_at > ?", 7.days.ago).find_each do |tour|
      SimplifyTourPointsJob.perform_later(tour.id, false)
    end
  end
end
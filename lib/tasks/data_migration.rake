namespace :data_migration do
  desc "cache recent tour points"
  task cache_tour_points: :environment do
    Tour.where("created_at > ?", 1.month.ago).find_each do |tour|
      puts "simplify tour #{tour.id}"
      SimplifyTourPointsJob.perform_later(tour.id, false)
    end
  end
end
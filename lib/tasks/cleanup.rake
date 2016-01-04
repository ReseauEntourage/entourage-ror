task force_close_tours: :environment do
  Rails.logger = Logger.new(STDOUT)
  CleanupService.force_close_tours
end
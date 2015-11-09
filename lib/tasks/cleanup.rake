task force_close_tours: :environment do
  Rails.logger = Logger.new(STDOUT)
  CleanupService.force_close_tours
end

task force_resend_tour_reports: :environment do
  Rails.logger = Logger.new(STDOUT)
  CleanupService.force_resend_tour_reports
end

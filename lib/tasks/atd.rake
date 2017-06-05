namespace :atd do
  task import: :environment do
    # ATD upload new files every saturday
    return unless Date.today.sunday?
    Rails.logger = Logger.new(STDOUT)
    Atd::AtdSynchronizer.synchronize
  end
end

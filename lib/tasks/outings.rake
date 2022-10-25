namespace :outings do
  desc "Generate outing recurrences"
  task generate_recurrences: :environment do
    OutingRecurrence.generate_all
  end
end

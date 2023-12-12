require 'tasks/outing_tasks'

namespace :outings do
  desc "Generate outing recurrences"
  task generate_recurrences: :environment do
    OutingRecurrence.generate_all
  end

  desc "send post to upcoming outings"
  task send_post_to_upcoming: :environment do
    OutingTasks::send_post_to_upcoming
  end
end

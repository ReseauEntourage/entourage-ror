require 'tasks/outing_tasks'

namespace :outings do
  desc 'Generate outing recurrences'
  task generate_recurrences: :environment do
    OutingRecurrence.generate_all
  end

  desc 'send email as reminder'
  task send_email_as_reminder: :environment do
    OutingTasks.send_email_as_reminder
  end

  desc 'send post to upcoming outings'
  task send_post_to_upcoming: :environment do
    OutingTasks::send_post_to_upcoming
  end

  desc 'send email with upcoming outings'
  task send_email_with_upcoming: :environment do
    return unless Time.zone.now.monday?

    OutingTasks::send_email_with_upcoming
  end
end

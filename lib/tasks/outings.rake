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

  desc 'send private_message 7 days before'
  task send_private_message_7_days_before: :environment do
    OutingTasks::send_private_message_7_days_before
  end

  desc 'send post to upcoming outings'
  task send_post_to_upcoming: :environment do
    OutingTasks::send_post_to_upcoming
  end

  desc "send chat_message to today outings"
  task send_chat_message_to_today: :environment do
    OutingTasks::send_chat_message_to_today
  end

  desc "send email with upcoming outings"
  task send_email_with_upcoming: :environment do
    return unless Time.zone.now.monday?

    OutingTasks::send_email_with_upcoming
  end
end

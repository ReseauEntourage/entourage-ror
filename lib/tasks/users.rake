namespace :users do
  desc 'Unblock a user'
  task unblock: :environment do
    UserServices::Unblock.run!
  end

  desc 'Celebrate a birthday'
  task celebrate_birthday: :environment do
    UserServices::Birthday.send_notifications
  end

  # Both tasks read denorm_daily_engagements_with_type, filled by the user-engagement
  # Lambda (entourage-tasks) daily at 05:00 UTC: schedule them after it.
  desc 'Refresh engagement_levels materialized view (Heroku Scheduler, daily at 06:00 UTC)'
  task engagement_levels: :environment do
    RefreshEngagementLevelsJob.perform_now
  end

  desc 'Compute and historize user engagement segments (Heroku Scheduler, daily at 06:00 UTC)'
  task engagement_segments: :environment do
    RefreshEngagementSegmentsJob.perform_now
  end
end

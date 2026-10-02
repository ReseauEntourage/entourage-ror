namespace :users do
  desc 'Unblock a user'
  task unblock: :environment do
    UserServices::Unblock.run!
  end

  desc 'Celebrate a birthday'
  task celebrate_birthday: :environment do
    UserServices::Birthday.send_notifications
  end

  desc 'Refresh engagement_levels materialized view (daily, Heroku Scheduler)'
  task engagement_levels: :environment do
    RefreshEngagementLevelsJob.perform_now
  end

  desc 'Compute and historize user engagement segments (daily, Heroku Scheduler)'
  task engagement_segments: :environment do
    RefreshEngagementSegmentsJob.perform_now
  end
end

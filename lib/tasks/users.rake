namespace :users do
  desc 'Unblock a user'
  task unblock: :environment do
    UserServices::Unblock.run!
  end

  # One-off. Reads only unless DRY_RUN=false. LIMIT=n restricts the number of accounts.
  desc 'Set back to blocked the deleted accounts whose last block was silently lost (DRY_RUN=false to write)'
  task restore_blocked_status: :environment do
    dry_run = ENV['DRY_RUN'] != 'false'
    limit = ENV['LIMIT'].presence&.to_i

    user_ids = UserServices::RestoreBlockedStatus.run!(dry_run: dry_run, limit: limit)

    puts "#{dry_run ? 'DRY RUN: would set' : 'Set'} #{user_ids.size} deleted account(s) to blocked"
    puts "ids: #{user_ids.first(20).join(', ')}#{' …' if user_ids.size > 20}" if user_ids.any?
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

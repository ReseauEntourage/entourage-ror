namespace :badges do
  desc "Update weekly activity and 'Vie de groupe' badge for active users"
  task update_weekly_activity: :environment do
    BadgeService.update_weekly_activity_from(Date.today)
  end
end

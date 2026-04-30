namespace :badges do
  desc "Update weekly activity and 'Vie de groupe' badge for active users"
  task update_weekly_activity: :environment do
    BadgesService.update_weekly_activity
  end
end

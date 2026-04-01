namespace :users do
  desc 'Unblock a user'
  task unblock: :environment do
    UserServices::Unblock.run!
  end

  desc 'Celebrate a birthday'
  task celebrate_birthday: :environment do
    UserServices::Birthday.send_notifications
  end

  desc 'Generates engagement_levels'
  task engagement_levels: :environment do
    UserServices::Engagement.generates_engagement_levels
  end
end

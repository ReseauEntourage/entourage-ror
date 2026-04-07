namespace :users do
  desc 'Unblock a user'
  task unblock: :environment do
    UserServices::Unblock.run!
  end

  desc 'Celebrate a birthday'
  task celebrate_birthday: :environment do
    UserServices::Birthday.send_notifications
  end
end

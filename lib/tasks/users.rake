namespace :users do
  task unblock: :environment do
    UserServices::Unblock.run!
  end
end

namespace :digest_email do
  task schedule_delivery: :environment do
    DigestEmailService.schedule_delivery!
  end

  task deliver_scheduled: :environment do
    DigestEmailService.deliver_scheduled!
  end
end

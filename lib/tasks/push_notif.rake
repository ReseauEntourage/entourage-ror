namespace :push do
  desc 'deliver_welcome'
  task deliver_welcome: :environment do
    Onboarding::TimelineDelivery.deliver_welcome
  end

  desc 'deliver_on(2)'
  task deliver_on_2: :environment do
    Onboarding::TimelineDelivery.deliver_on(2)
  end

  desc 'deliver_on(5)'
  task deliver_on_5: :environment do
    Onboarding::TimelineDelivery.deliver_on(5)
  end

  desc 'deliver_on(8)'
  task deliver_on_8: :environment do
    Onboarding::TimelineDelivery.deliver_on(8)
  end

  desc 'deliver_on(11)'
  task deliver_on_11: :environment do
    Onboarding::TimelineDelivery.deliver_on(11)
  end

  desc 'deliver_on(outing_day_before)'
  task deliver_on_outing_day_before: :environment do
    tomorrow = Time.zone.tomorrow

    Outing.between(tomorrow.beginning_of_day, tomorrow.end_of_day).find_each(batch_size: 10) do |outing|
      PushNotificationTrigger.new(outing, :day_before, Hash.new).run
    end
  end
end

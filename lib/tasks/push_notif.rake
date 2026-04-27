namespace :push do
  desc 'deliver_welcome'
  task deliver_welcome: :environment do
    Onboarding::TimelineDelivery.deliver_welcome
  end

  desc 'deliver_on(outing_day_before)'
  task deliver_on_outing_day_before: :environment do
    tomorrow = Time.zone.tomorrow

    Outing.active.between(tomorrow.beginning_of_day, tomorrow.end_of_day).find_each(batch_size: 10) do |outing|
      PushNotificationTrigger.new(outing, :day_before, Hash.new).run
    end
  end
end

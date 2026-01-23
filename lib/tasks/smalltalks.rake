namespace :smalltalks do
  desc 'close_unmatched'
  task close_unmatched: :environment do
    SmalltalkServices::Matcher.close_unmatched
  end

  desc 'match_pending'
  task match_pending: :environment do
    SmalltalkServices::Matcher.match_pending
  end

  desc "schedule_meet_creation"
  task schedule_meet_creation: :environment do
    SmalltalkServices::Meeter.schedule_meet_creation
  end

  desc "Inactivity"
  task inactivity: :environment do
    [3, 5, 7].each do |days|
      SmalltalkServices::Inactivity.new(days).chat_messages!
    end
  end
end

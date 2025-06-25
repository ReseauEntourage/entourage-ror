namespace :smalltalks do
  desc "match_pending"
  task match_pending: :environment do
    SmalltalkServices::Matcher.match_pending
  end

  desc "Inactivity"
  task inactivity: :environment do
    [3, 5, 7].each do |days|
      SmalltalkServices::Inactivity.new(days).chat_messages!
    end
  end
end

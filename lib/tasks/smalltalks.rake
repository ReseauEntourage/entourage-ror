namespace :smalltalks do
  desc "close_unmatched"
  task close_unmatched: :environment do
    SmalltalkServices::Matcher.close_unmatched
  end

  desc "match_pending"
  task match_pending: :environment do
    SmalltalkServices::Matcher.match_pending
  end
end

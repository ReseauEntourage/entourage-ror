namespace :smalltalks do
  desc "match_pending"
  task match_pending: :environment do
    SmalltalkServices::Matcher.match_pending
  end
end

namespace :match do
  desc "Try to match every unmatched user_smalltalks"
  task users: :environment do
    UserSmalltalkMatchingJob.new.perform

    puts "🎉 Matching done."
  end
end

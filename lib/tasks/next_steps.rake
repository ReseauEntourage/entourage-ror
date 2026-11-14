namespace :next_steps do
  desc 'Warn Sentry when no papotage is scheduled within 7 days, or when the engagement segments are more than 2 days old (Heroku Scheduler, daily)'
  task alert: :environment do
    NextSteps::Alert.call
  end

  desc 'Delete the next steps and the interactions older than 6 months (Heroku Scheduler, daily)'
  task purge: :environment do
    deleted = NextSteps::Purge.expired

    puts "next_steps:purge #{deleted.map { |table, count| "#{table}=#{count}" }.join(' ')}"
  end
end

namespace :next_steps do
  desc 'Warn Sentry when no papotage is scheduled within 7 days, or when the engagement segments are more than 2 days old (Heroku Scheduler, daily)'
  task alert: :environment do
    NextSteps::Alert.call
  end
end

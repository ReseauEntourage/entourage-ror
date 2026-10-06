require 'tasks/salesforce_tasks'

namespace :salesforce do
  # dry run by default; options: SINCE=2026-04-29 AFTER_ID=<user_id> LIMIT=<n> DRY_RUN=false
  desc 'Resync users with Salesforce (users updated since the Compte_App__c sync bug)'
  task resync_users: :environment do
    since = ENV['SINCE'].present? ? Date.parse(ENV['SINCE']) : SalesforceTasks::USERS_SYNC_BROKEN_SINCE
    dry_run = ENV['DRY_RUN'] != 'false'

    if api_requests = SalesforceTasks.daily_api_requests
      puts "Salesforce daily API requests: #{api_requests['Remaining']} remaining / #{api_requests['Max']}"
    end

    user_ids = SalesforceTasks.resync_users(
      since: since,
      after_id: ENV['AFTER_ID'].presence&.to_i,
      limit: ENV['LIMIT'].presence&.to_i,
      dry_run: dry_run
    )

    puts "#{user_ids.size} users #{dry_run ? 'to resync (dry run)' : 'enqueued'} since #{since}, ~#{user_ids.size * SalesforceTasks::API_CALLS_PER_USER} API calls"
    puts "last user id: #{user_ids.last} (use AFTER_ID=#{user_ids.last} for the next batch)" if user_ids.any?
  end
end

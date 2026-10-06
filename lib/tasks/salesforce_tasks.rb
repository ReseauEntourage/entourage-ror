module SalesforceTasks
  # EN-8831 (merged on 2026-04-29) made every Compte_App__c upsert/update fail
  USERS_SYNC_BROKEN_SINCE = Date.new(2026, 4, 29)

  # Lead lookup, Contact lookup/upsert, Contact update, Compte_App__c upsert
  API_CALLS_PER_USER = 6

  class << self
    def users_to_resync since: USERS_SYNC_BROKEN_SINCE, after_id: nil
      users = User
        .joins(:address)
        .where(deleted: false)
        .where(salesforce_id: nil)
        .where('users.updated_at >= :since OR users.last_sign_in_at >= :since OR addresses.updated_at >= :since', since: since)

      users = users.where('users.id > ?', after_id) if after_id.present?
      users.order(:id)
    end

    # returns the ids of the users to resync (dry_run) or enqueued
    def resync_users since: USERS_SYNC_BROKEN_SINCE, after_id: nil, limit: nil, dry_run: true
      user_ids = users_to_resync(since: since, after_id: after_id).limit(limit).pluck(:id)

      return user_ids if dry_run

      user_ids.each do |user_id|
        SalesforceJob.perform_async('User', user_id, 'upsert')
      end
    end

    def daily_api_requests
      SalesforceServices::Connect.client.limits['DailyApiRequests']
    rescue StandardError
      nil
    end
  end
end

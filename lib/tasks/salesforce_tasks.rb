module SalesforceTasks
  # EN-8831 (merged on 2026-04-29) made every Compte_App__c upsert/update fail
  USERS_SYNC_BROKEN_SINCE = Date.new(2026, 4, 29)

  # Lead lookup, Contact lookup/upsert, Contact update, Compte_App__c upsert
  API_CALLS_PER_USER = 6

  OUTING_TABLE = 'Campaign'
  MEETING_LINK_FIELD = 'MeetingLink__c'

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

    # EN-8689: online outings already linked to a Salesforce Campaign, with a meeting link
    def outings_with_meeting_link since:
      Outing
        .reorder(:id)
        .where(online: true)
        .where.not(salesforce_id: [nil, ''])
        .where.not(event_url: [nil, ''])
        .where("metadata->>'starts_at' >= ?", since.to_date.to_s)
    end

    # EN-8689: writes Campaign.MeetingLink__c only, for Campaigns whose value differs (idempotent).
    # Reads the database with a single pluck: no model saved, so no callback, notification or job.
    def backfill_meeting_links since:, dry_run: true, pause: 0.1
      client = SalesforceServices::Connect.client

      field = client.describe(OUTING_TABLE)['fields'].find { |f| f['name'] == MEETING_LINK_FIELD }
      raise "#{OUTING_TABLE}.#{MEETING_LINK_FIELD} not found in Salesforce" unless field
      raise "#{OUTING_TABLE}.#{MEETING_LINK_FIELD} is not updateable by the API user" unless field['updateable']

      max_length = field['length'].to_i
      rows = outings_with_meeting_link(since: since).pluck(:id, :salesforce_id, :event_url, :status)
      report = { statuses: rows.map(&:last).tally, updated: [], up_to_date: [], not_found: [], too_long: [], errors: [] }

      return report if rows.empty?

      # current values, keyed on the 15-char id (salesforce_id may be stored with 15 or 18 chars)
      ids = rows.map { |row| "'#{row[1]}'" }.uniq.join(',')
      current = client.query("SELECT Id, #{MEETING_LINK_FIELD} FROM #{OUTING_TABLE} WHERE Id IN (#{ids})").to_h do |record|
        [record['Id'][0, 15], record[MEETING_LINK_FIELD]]
      end

      rows.each do |outing_id, salesforce_id, event_url, _status|
        key = salesforce_id[0, 15]

        next report[:not_found] << outing_id unless current.key?(key)
        next report[:up_to_date] << outing_id if current[key] == event_url
        next report[:too_long] << outing_id if max_length.positive? && event_url.length > max_length

        unless dry_run
          begin
            client.update!(OUTING_TABLE, { Id: salesforce_id, MEETING_LINK_FIELD => event_url })
            sleep pause
          rescue StandardError => e
            next report[:errors] << [outing_id, e.message]
          end
        end

        report[:updated] << [outing_id, current[key], event_url]
      end

      report
    end
  end
end

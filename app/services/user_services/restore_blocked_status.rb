module UserServices
  # Until User#block! stopped validating the record, blocking an account that had already been
  # deleted wrote the 'block' history but silently left its status on 'deleted' (the suffixed
  # phone of a deleted account fails the phone validation).
  #
  # This sets such accounts back to 'blocked': deleted accounts whose latest block / unblock
  # history is a block. No callback runs (no notification, no Salesforce sync): the accounts are
  # already deleted and their groups already closed.
  class RestoreBlockedStatus
    LAST_BLOCK_HISTORY_KIND = <<~SQL.squish
      (
        SELECT user_histories.kind
        FROM user_histories
        WHERE user_histories.user_id = users.id
          AND user_histories.kind IN ('block', 'unblock')
        ORDER BY user_histories.created_at DESC, user_histories.id DESC
        LIMIT 1
      )
    SQL

    def self.users
      User
        .where(deleted: true, validation_status: 'deleted')
        .where("#{LAST_BLOCK_HISTORY_KIND} = 'block'")
    end

    # returns the ids concerned; writes only when dry_run is false
    def self.run!(dry_run: true, limit: nil)
      user_ids = users.order(:id).limit(limit).pluck(:id)

      return user_ids if dry_run || user_ids.empty?

      User.where(id: user_ids).update_all(validation_status: 'blocked', updated_at: Time.current)

      user_ids
    end
  end
end

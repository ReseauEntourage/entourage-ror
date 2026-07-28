class ReconcileUnreadMessagesCountsJob < ApplicationJob
  queue_as :default

  # UnreadChatMessageJob only runs once per ChatMessage event, and nothing
  # else ever recomputes join_requests.unread_messages_count afterwards — so
  # any run that's lost (Sidekiq restart mid-job, a transient DB error past
  # its retries, ...) leaves the counter wrong indefinitely, until the next
  # message arrives on that same conversation and its own job succeeds.
  #
  # This sweep re-triggers UnreadChatMessageJob (idempotent full recompute,
  # ~10ms per conversation, deduped via its `lock: :until_executed`) for
  # every Entourage with recent chat activity, so a lost run gets corrected
  # on the next sweep instead of staying wrong forever.
  LOOKBACK = 1.hour

  def perform
    ChatMessage
      .where(messageable_type: 'Entourage')
      .where('created_at > ?', LOOKBACK.ago)
      .distinct
      .pluck(:messageable_id)
      .each { |messageable_id| UnreadChatMessageJob.perform_later('Entourage', messageable_id) }
  end
end

class UserImpactStatsObserver < ActiveRecord::Observer
  # @see UserStat
  # chat message triggers live in DenormChatMessageObserver
  observe :entourage

  def after_commit record
    return unless record.is_a?(Entourage)
    return unless record.action?
    return unless commit_is?(record, [:create, :destroy]) || record.saved_change_to_status?

    UserImpactStatsJob.perform_async(record.user_id, UserStat::ACTION_CREATIONS)
  rescue => e
    # we never want to fail the action write because of a counter
    Rails.logger.warn "UserImpactStatsObserver #{e.message}"
  end

  private

  def commit_is? record, actions
    record.send(:transaction_include_any_action?, actions)
  end
end

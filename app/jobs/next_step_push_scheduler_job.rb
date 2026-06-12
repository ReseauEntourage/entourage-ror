class NextStepPushSchedulerJob
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform
    base_scope = User
      .where(community: :entourage, deleted: false, validation_status: 'validated')

    # Batch 1: New users who signed up 2-3 days ago with no join requests
    base_scope
      .where(first_sign_in_at: 3.days.ago..2.days.ago)
      .left_joins(:join_requests)
      .group('users.id')
      .having('COUNT(join_requests.id) = 0')
      .find_each do |user|
        NextStepPushJob.perform_async(user.id)
      end

    # Batch 2: Users whose active suggestion has recently expired (25h ago to 1h ago)
    expired_user_ids = UserNextStep
      .active_status
      .where(expires_at: 25.hours.ago..1.hour.ago)
      .pluck(:user_id)

    base_scope.where(id: expired_user_ids).find_each do |user|
      NextStepPushJob.perform_async(user.id)
    end

    # Batch 3: Dormant users (last sign in between 30 and 45 days ago)
    base_scope
      .where(last_sign_in_at: 45.days.ago..30.days.ago)
      .find_each do |user|
        NextStepPushJob.perform_async(user.id)
      end
  end
end

namespace :onboarding_sequence do
  desc "send_emails"
  task send_emails: :environment do
    def at_day n, options={}, &block
      DailyTaskHelper.at_day n, options, &block
    end

    target_hour = [8, 30]

    current_run_at = Time.zone.now
    redis_key = 'onboarding_sequence:last_run'
    redis_date = current_run_at.strftime('%Y-%m-%d')
    last_run_at = $redis.get(redis_key)

    if last_run_at
      last_run_at = Time.zone.parse(last_run_at)
      # never run twice on the same date
      next unless current_run_at.midnight > last_run_at.midnight
    end

    # only run at or after target hour
    next unless ([current_run_at.hour, current_run_at.min] <=> target_hour) >= 0

    # at_day 8, after: :registration do |user|
    #   MemberMailer.onboarding_day_8(user).deliver_later
    # end

    at_day 14, after: :registration do |user|
      MemberMailer.onboarding_day_14(user).deliver_later
    end

    at_day 20, after: :last_session do |user|
      MemberMailer.reactivation_day_20(user).deliver_later
    end

    at_day 15, after: :action_creation do |action|
      MemberMailer.action_follow_up_day_15(action).deliver_later
    end

    $redis.set(redis_key, redis_date)
  end

  desc "send_incomplete_profile_email"
  task send_incomplete_profile_email: :environment do
    Onboarding::EmailerService.deliver_incomplete_profile_email
  end

  desc "send_welcome_messages"
  task send_welcome_messages: :environment do
    Onboarding::ChatMessagesService.deliver_welcome_message
  end

  desc "send_ethical_messages"
  task send_ethical_messages: :environment do
    Onboarding::ChatMessagesService.deliver_ethical_charter
  end
end

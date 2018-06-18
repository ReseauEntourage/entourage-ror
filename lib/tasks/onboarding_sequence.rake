namespace :onboarding_sequence do
  task send_emails: :environment do
    def most_common_postal_code entourages
      entourages.where(country: :FR)
                .group(:postal_code)
                .order('count_all desc')
                .limit(1)
                .count
                .first
                .try(:first)
    end

    target_date = 3.days.ago
    target_hour = [8, 30]

    current_run_at = Time.zone.now
    redis_key = 'onboarding_sequence:j+3:last_run'
    redis_date = current_run_at.strftime('%Y-%m-%d')
    last_run_at = $redis.get(redis_key)

    if last_run_at
      last_run_at = Time.zone.parse(last_run_at)
      # never run twice on the same date
      next unless current_run_at.midnight > last_run_at.midnight
    end

    # only run at or after target hour
    next unless ([current_run_at.hour, current_run_at.min] <=> target_hour) >= 0

    User.where(onboarding_sequence_start_at: target_date.all_day)
        .find_each do |user|

      begin
        postal_code =
          most_common_postal_code(user.entourages) ||
          most_common_postal_code(user.entourage_participations) ||
          "75001"

        MemberMailer.action_zone_suggestion(user, postal_code).deliver_later
      rescue => e
        Raven.capture_exception(e, extra: { user_id: user.id })
      end
    end

    $redis.set(redis_key, redis_date)
  end
end

namespace :onboarding_sequence do
  task send_emails: :environment do
    def at_day n, &block
      User.where(onboarding_sequence_start_at: n.days.ago.all_day)
        .find_each do |user|
          begin
            yield user
          rescue => e
            Raven.capture_exception(e, extra: { user_id: user.id })
          end
        end
    end

    def most_common_postal_code entourages
      entourages.where(country: :FR)
                .group(:postal_code)
                .order('count_all desc')
                .limit(1)
                .count
                .first
                .try(:first)
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

    at_day 3 do |user|
      postal_code =
        most_common_postal_code(user.entourages) ||
        most_common_postal_code(user.entourage_participations) ||
        "75001"

      MemberMailer.action_zone_suggestion(user, postal_code).deliver_later
    end

    at_day 14 do |user|
      MemberMailer.onboarding_day_14(user).deliver_later
    end

    $redis.set(redis_key, redis_date)
  end
end

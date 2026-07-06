class BadgeDeactivationWarningJob < ApplicationJob
  queue_as :default

  REVERSIBLE_BADGES = %w[fidele_papotages voix_presente moteur_rencontres].freeze
  TARGET = 3
  # Outings/papotages window minus 7 days to detect risk at J+7
  J7_WINDOW_DAYS = 83
  # Mirror the badge's sliding window to prevent duplicate warnings per cycle
  DEDUP_WINDOW_DAYS = 90

  def perform
    REVERSIBLE_BADGES.each { |badge_tag| process_badge(badge_tag) }
  end

  private

  def process_badge(badge_tag)
    UserBadge.where(badge_tag: badge_tag, active: true)
             .includes(:user)
             .find_each do |user_badge|
      user = user_badge.user
      next unless BadgeService.eligible_user?(user)
      next if already_warned?(user.id, badge_tag)

      current = count_at_j7(user, badge_tag)
      next unless current.between?(1, TARGET - 1)

      BadgeMailer.deactivation_warning(user, badge_tag, current, TARGET).deliver_later
    end
  end

  def count_at_j7(user, badge_tag)
    case badge_tag
    when 'moteur_rencontres'
      Outing.accepted
            .where(user_id: user.id)
            .where(created_at: J7_WINDOW_DAYS.days.ago..Time.now)
            .count
    when 'fidele_papotages'
      JoinRequest.accepted
                 .where.not(participate_at: nil)
                 .where(user_id: user.id, joinable_type: 'Entourage')
                 .where(joinable_id: Outing.papotages.between(J7_WINDOW_DAYS.days.ago, Time.now))
                 .count
    when 'voix_presente'
      cutoff_week = J7_WINDOW_DAYS.days.ago.to_date.strftime('%G-W%V')
      WeeklyActivity.where(user_id: user.id)
                    .where('week_iso >= ?', cutoff_week)
                    .count
    end
  end

  def already_warned?(user_id, badge_tag)
    EmailDelivery
      .for_campaign("badge_warning_#{badge_tag}")
      .where(user_id: user_id)
      .where('sent_at > ?', DEDUP_WINDOW_DAYS.days.ago)
      .exists?
  end
end

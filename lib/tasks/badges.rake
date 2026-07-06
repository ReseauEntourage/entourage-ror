namespace :badges do
  desc "Send deactivation warning emails for reversible badges at risk of expiring within 7 days"
  task deactivation_warning: :environment do
    BadgeDeactivationWarningJob.perform_now
  end


  desc "Update weekly activity and 'Vie de groupe' badge for active users"
  task update_weekly_activity: :environment do
    BadgeService.update_weekly_activity_from(Date.today)
  end

  desc "Recalculate 'Moteur de rencontres' badge for users whose badge status may have changed"
  task recalculate_moteur_rencontres: :environment do
    # Users with active badge (may need deactivation if outings slid out of the 90-day window)
    user_ids = UserBadge.where(badge_tag: 'moteur_rencontres', active: true).pluck(:user_id)

    # Users whose outings are currently crossing the 90-day boundary (±5 days)
    user_ids |= Outing.accepted
      .where(created_at: 95.days.ago..85.days.ago)
      .pluck(:user_id)

    User.where(id: user_ids).find_each do |user|
      BadgeService.check_moteur_rencontres(user)
    end
  end

  desc "Recalculate all badges (except 'premier_contact', which is event-driven) for users active in the last 30 days, without sending any notification or email"
  task recalculate_all: :environment do
    user_ids = SessionHistory
      .where('date >= ?', 30.days.ago.to_date)
      .distinct
      .pluck(:user_id)

    puts "Recalculating badges for #{user_ids.size} users active in the last 30 days..."

    # `notify: false` skips the congratulations/deactivation emails (BadgeService);
    # disabling the observer skips the push/in-app/cable notification triggered on save.
    UserBadge.observers.disable(:push_notification_trigger_observer) do
      User.where(id: user_ids).find_each do |user|
        BadgeService.check_bienvenue(user, notify: false)
        BadgeService.check_moteur_rencontres(user, notify: false)
        BadgeService.check_fidele_papotages(user, notify: false)
        BadgeService.check_voix_presente(user, notify: false)
      end
    end

    puts "Done."
  end
end

class BadgeMailer < MailjetMailer
  REVERSIBLE_BADGE_TAGS = %w[fidele_papotages voix_presente moteur_rencontres].freeze
  MINIMUM_DURATION_DAYS = 7

  def deactivation_warning(user, badge_tag, current, target)
    return unless REVERSIBLE_BADGE_TAGS.include?(badge_tag)

    locale = user.lang
    name        = I18n.t("badge_mailer.badges.#{badge_tag}.name", locale: locale)
    description = I18n.t("badge_mailer.badges.#{badge_tag}.description", locale: locale)
    progression_label = I18n.t(
      "badge_mailer.badges.#{badge_tag}.progression_label.#{current}",
      locale: locale,
      default: nil
    )
    return unless progression_label

    progression_pct = ((current.to_f / target) * 100).round
    image_url  = UserBadge.image_url_for(badge_tag)
    deeplink   = UserBadge.share_url_for_badge_tag(badge_tag)

    mailjet_email(
      to: user,
      template_id: 8099655,
      campaign_name: "badge_warning_#{badge_tag}",
      unsubscribe_category: :default,
      variables: {
        badge_image_url: image_url,
        badge_nom: name,
        badge_description: description,
        progression_label: progression_label,
        progression_pct: progression_pct,
        deeplink_badge: deeplink,
        badge_url: deeplink
      }
    )
  end

  def deactivated(user, badge_tag, awarded_at, deactivated_at)
    return unless REVERSIBLE_BADGE_TAGS.include?(badge_tag)
    return if awarded_at.blank? || deactivated_at.blank?
    return if (deactivated_at.to_date - awarded_at.to_date).to_i < MINIMUM_DURATION_DAYS

    locale = user.lang
    name = I18n.t("badge_mailer.badges.#{badge_tag}.name", locale: locale)
    image_url = I18n.t("badge_mailer.badges.#{badge_tag}.image_url", locale: locale, default: '')
    deeplink = I18n.t("badge_mailer.badges.#{badge_tag}.deeplink", locale: locale, default: '')
    awarded_date = I18n.l(awarded_at.to_date, format: :long, locale: locale)

    mailjet_email(
      to: user,
      template_id: 8103988,
      campaign_name: "badge_deactivated_#{badge_tag}",
      unsubscribe_category: :default,
      variables: {
        badge_image_url: image_url,
        badge_nom: name,
        badge_duree: duration_label(awarded_at, deactivated_at, locale),
        badge_bilan: I18n.t("badge_mailer.badges.#{badge_tag}.bilan", locale: locale, date: awarded_date),
        deeplink_badge: deeplink
      }
    )
  end

  private

  def duration_label(awarded_at, deactivated_at, locale)
    I18n.t('badge_mailer.duration', count: duration_in_months(awarded_at, deactivated_at), locale: locale)
  end

  def duration_in_months(awarded_at, deactivated_at)
    months = (deactivated_at.year * 12 + deactivated_at.month) - (awarded_at.year * 12 + awarded_at.month)
    months -= 1 if deactivated_at.day < awarded_at.day
    [months, 0].max
  end
end

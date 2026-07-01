class BadgeMailer < MailjetMailer
  REVERSIBLE_BADGE_TAGS = %w[fidele_papotages voix_presente moteur_rencontres].freeze

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
    image_url  = I18n.t("badge_mailer.badges.#{badge_tag}.image_url", locale: locale, default: '')
    deeplink   = I18n.t("badge_mailer.badges.#{badge_tag}.deeplink", locale: locale, default: '')

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
        deeplink_badge: deeplink
      }
    )
  end
end

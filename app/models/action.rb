class Action < Entourage
  include Actionable
  include Matchable
  include Recommandable
  include Sectionable

  default_scope { where(group_type: :action, entourage_type: [:ask_for_help, :contribution]).order(created_at: :desc) }

  scope :with_moderation_area, -> (moderation_area) {
    return unless moderation_area
    return if moderation_area.to_sym == :all

    if moderation_area.present? && moderation_area.to_sym == :hors_zone
      return where("left(postal_code, 2) not in (?)", ModerationArea.only_departements).or(
        where.not(country: :FR)
      )
    end

    where("left(postal_code, 2) = ?", ModerationArea.departement(moderation_area)).where(country: :FR)
  }

  scope :filtered_with_user_profile, -> (user) {
    return where(entourage_type: :contribution) if user.is_ask_for_help?

    where(entourage_type: :ask_for_help)
  }
end

class Action < Entourage
  include Actionable
  include Matchable
  include Recommandable
  include Sectionable

  default_scope { where(group_type: :action, entourage_type: [:ask_for_help, :contribution]).order(created_at: :desc) }

  scope :filtered_with_user_profile, -> (user) {
    return where(entourage_type: :contribution) if user.is_ask_for_help?

    where(entourage_type: :ask_for_help)
  }

  scope :with_moderated, -> (moderated) {
    return unless moderated.present?
    return where("entourage_moderations.moderated_at is not null or entourages.created_at < '2018-01-01'") if ActiveModel::Type::Boolean.new.cast(moderated)

    where("entourage_moderations.moderated_at is null and entourages.created_at > '2018-01-01'")
  }
end
